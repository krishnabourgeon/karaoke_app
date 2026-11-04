// import 'dart:async';
// import 'dart:io';

// import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';
// import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
// import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
// import 'package:ffmpeg_kit_flutter_new_audio/statistics.dart';
// import 'package:flutter/foundation.dart';
// import 'package:karaoke_app/model/mix_settings.dart';
// import 'package:karaoke_app/service/audio_effects_processor.dart';
// import 'package:karaoke_app/service/karaoke_files.dart';
// import 'package:karaoke_app/service/mix_timing.dart';

// class MixOutput {
//   final String path;
//   final bool isVideo;
//   const MixOutput(this.path, {required this.isVideo});
// }

// class AudioMixer {
//   AudioMixer._();

//   static const cancelledMessage = 'Mixing was cancelled.';

//   /// Video or any audio file → AAC m4a (audio only).
//   static Future<void> extractAudio(String input, String output) async {
//     final session = await FFmpegKit.executeWithArguments([
//       '-y', '-i', input,
//       '-vn', '-map', '0:a:0',
//       '-c:a', 'aac', '-b:a', '192k', '-ar', '44100',
//       output,
//     ]);
//     if (!ReturnCode.isSuccess(await session.getReturnCode())) {
//       debugPrint('FFmpeg extract failed:\n${await session.getAllLogsAsString()}');
//       await KaraokeFiles.instance.deleteIfExists(output);
//       throw const KaraokeException('Could not read audio from this file. Try another song.');
//     }
//   }

//   /// Length of a media file, or null when FFprobe cannot read it.
//   static Future<Duration?> probeDuration(String path) async {
//     final info = (await FFprobeKit.getMediaInformation(path)).getMediaInformation();
//     final seconds = double.tryParse(info?.getDuration() ?? '');
//     return seconds == null ? null : Duration(milliseconds: (seconds * 1000).round());
//   }

//   /// Renders [window] of the song with [settings] into [outputPath].
//   ///
//   /// The source files are only read. With [videoPath] the original picture
//   /// is copied (not re-encoded) into an mp4; if that fails the caller should
//   /// retry without video. [onSession] gives the id for [cancelSession].
//   static Future<MixOutput> render({
//     required String backingPath,
//     required String vocalsPath,
//     required MixSettings settings,
//     required MixWindow window,
//     required String outputPath,
//     ExportFormat format = ExportFormat.m4a,
//     String? videoPath,
//     bool validate = true,
//     void Function(double progress)? onProgress,
//     void Function(int sessionId)? onSession,
//   }) async {
//     if (!await File(vocalsPath).exists()) {
//       throw const KaraokeException('Your recording is missing. Please record again.');
//     }
//     if (!await File(backingPath).exists()) {
//       throw const KaraokeException('The karaoke track is missing. Reopen the song and try again.');
//     }
//     if (window.durationMs <= 0) {
//       throw const KaraokeException('There is nothing to mix. Check the trim points.');
//     }

//     final withVideo = videoPath != null;
//     final start = ffSeconds(window.musicSeekMs);
//     final length = ffSeconds(window.durationMs);
//     final filter = AudioEffectsProcessor.buildFilterGraph(
//         settings, vocalDelayMs: window.vocalDelayMs);

//     final args = <String>[
//       '-y',
//       '-ss', start, '-t', length, '-i', backingPath,
//       if (window.vocalSeekMs > 0) ...['-ss', ffSeconds(window.vocalSeekMs)],
//       '-i', vocalsPath,
//       if (withVideo) ...['-ss', start, '-t', length, '-i', videoPath],
//       '-filter_complex', filter,
//       '-map', '[out]',
//       if (withVideo) ...['-map', '2:v:0', '-c:v', 'copy'],
//       ..._audioCodec(withVideo ? ExportFormat.m4a : format),
//       if (withVideo || format == ExportFormat.m4a) ...['-movflags', '+faststart'],
//       '-t', length,
//       outputPath,
//     ];

//     final done = Completer<void>();
//     final session = await FFmpegKit.executeWithArgumentsAsync(
//       args,
//       (FFmpegSession session) async {
//         final code = await session.getReturnCode();
//         if (ReturnCode.isSuccess(code)) {
//           done.complete();
//         } else if (ReturnCode.isCancel(code)) {
//           done.completeError(const KaraokeException(cancelledMessage));
//         } else {
//           debugPrint('FFmpeg mix failed ($code):\n${await session.getAllLogsAsString()}');
//           done.completeError(const KaraokeException('Mixing failed. Please try again.'));
//         }
//       },
//       null,
//       (Statistics stats) {
//         onProgress?.call((stats.getTime() / window.durationMs).clamp(0.0, 1.0));
//       },
//     );
//     final id = session.getSessionId();
//     if (id != null) onSession?.call(id);

//     try {
//       await done.future;
//       if (validate) {
//         await _validate(outputPath,
//             expectedMs: window.durationMs, requireVideo: withVideo);
//       }
//     } catch (_) {
//       await KaraokeFiles.instance.deleteIfExists(outputPath);
//       rethrow;
//     }
//     return MixOutput(outputPath, isVideo: withVideo);
//   }

//   /// Stops one running render; [render] then throws [cancelledMessage].
//   static Future<void> cancelSession(int sessionId) => FFmpegKit.cancel(sessionId);

//   static List<String> _audioCodec(ExportFormat format) => switch (format) {
//         ExportFormat.m4a => ['-c:a', 'aac', '-b:a', '192k'],
//         ExportFormat.mp3 => ['-c:a', 'libmp3lame', '-b:a', '192k'],
//         ExportFormat.wav => ['-c:a', 'pcm_s16le'],
//       };

//   /// A render only counts when the file has the expected streams and length.
//   static Future<void> _validate(String path,
//       {required int expectedMs, required bool requireVideo}) async {
//     final file = File(path);
//     if (!await file.exists() || await file.length() == 0) {
//       throw const KaraokeException('Mixing produced an empty file. Please try again.');
//     }
//     final info = (await FFprobeKit.getMediaInformation(path)).getMediaInformation();
//     final streams = info?.getStreams() ?? const [];
//     final hasAudio = streams.any((s) => s.getType() == 'audio');
//     final hasVideo = streams.any((s) => s.getType() == 'video');
//     final seconds = double.tryParse(info?.getDuration() ?? '');
//     if (!hasAudio || (requireVideo && !hasVideo)) {
//       throw const KaraokeException('The mixed file is missing audio or video.');
//     }
//     if (seconds != null) {
//       final diff = (seconds * 1000 - expectedMs).abs();
//       if (diff > 1500) {
//         debugPrint('Mix length ${seconds}s, expected ${expectedMs / 1000}s');
//         throw const KaraokeException('The mix came out the wrong length. Please try again.');
//       }
//     }
//   }
// }




import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_audio/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:karaoke_app/model/mix_settings.dart';
import 'package:karaoke_app/service/audio_effects_processor.dart';
import 'package:karaoke_app/service/karaoke_files.dart';
import 'package:karaoke_app/service/mix_timing.dart';

class MixOutput {
  final String path;
  final bool isVideo;
  const MixOutput(this.path, {required this.isVideo});
}

class AudioMixer {
  AudioMixer._();

  static const cancelledMessage = 'Mixing was cancelled.';

  /// Video or any audio file → AAC m4a (audio only).
  static Future<void> extractAudio(String input, String output) async {
    final session = await FFmpegKit.executeWithArguments([
      '-y', '-i', input,
      '-vn', '-map', '0:a:0',
      '-c:a', 'aac', '-b:a', '192k', '-ar', '44100',
      output,
    ]);
    if (!ReturnCode.isSuccess(await session.getReturnCode())) {
      debugPrint('FFmpeg extract failed:\n${await session.getAllLogsAsString()}');
      await KaraokeFiles.instance.deleteIfExists(output);
      throw const KaraokeException('Could not read audio from this file. Try another song.');
    }
  }

  /// Length of a media file, or null when FFprobe cannot read it.
  static Future<Duration?> probeDuration(String path) async {
    final info = (await FFprobeKit.getMediaInformation(path)).getMediaInformation();
    final seconds = double.tryParse(info?.getDuration() ?? '');
    return seconds == null ? null : Duration(milliseconds: (seconds * 1000).round());
  }

  /// Renders [window] of the song with [settings] into [outputPath].
  ///
  /// The source files are only read. With [videoPath] the original picture
  /// is copied (not re-encoded) into an mp4; if that fails the caller should
  /// retry without video. [onSession] gives the id for [cancelSession].
  static Future<MixOutput> render({
    required String backingPath,
    required String vocalsPath,
    required MixSettings settings,
    required MixWindow window,
    required String outputPath,
    ExportFormat format = ExportFormat.m4a,
    String? videoPath,
    bool validate = true,
    void Function(double progress)? onProgress,
    void Function(int sessionId)? onSession,
  }) async {
    if (!await File(vocalsPath).exists()) {
      throw const KaraokeException('Your recording is missing. Please record again.');
    }
    if (!await File(backingPath).exists()) {
      throw const KaraokeException('The karaoke track is missing. Reopen the song and try again.');
    }
    if (window.durationMs <= 0) {
      throw const KaraokeException('There is nothing to mix. Check the trim points.');
    }

    final withVideo = videoPath != null;
    final start = ffSeconds(window.musicSeekMs);
    final length = ffSeconds(window.durationMs);
    final filter = AudioEffectsProcessor.buildFilterGraph(
        settings, vocalDelayMs: window.vocalDelayMs);

    final args = <String>[
      '-y',
      '-ss', start, '-t', length, '-i', backingPath,
      if (window.vocalSeekMs > 0) ...['-ss', ffSeconds(window.vocalSeekMs)],
      '-i', vocalsPath,
      if (withVideo) ...['-ss', start, '-t', length, '-i', videoPath],
      '-filter_complex', filter,
      '-map', '[out]',
      if (withVideo) ...['-map', '2:v:0', '-c:v', 'copy'],
      ..._audioCodec(withVideo ? ExportFormat.m4a : format),
      if (withVideo || format == ExportFormat.m4a) ...['-movflags', '+faststart'],
      '-t', length,
      outputPath,
    ];

    final done = Completer<void>();
    final session = await FFmpegKit.executeWithArgumentsAsync(
      args,
      (FFmpegSession session) async {
        final code = await session.getReturnCode();
        if (ReturnCode.isSuccess(code)) {
          done.complete();
        } else if (ReturnCode.isCancel(code)) {
          done.completeError(const KaraokeException(cancelledMessage));
        } else {
          debugPrint('FFmpeg mix failed ($code):\n${await session.getAllLogsAsString()}');
          done.completeError(const KaraokeException('Mixing failed. Please try again.'));
        }
      },
      null,
      (Statistics stats) {
        onProgress?.call((stats.getTime() / window.durationMs).clamp(0.0, 1.0));
      },
    );
    final id = session.getSessionId();
    if (id != null) onSession?.call(id);

    try {
      await done.future;
      if (validate) {
        await _validate(outputPath,
            expectedMs: window.durationMs, requireVideo: withVideo);
      }
    } catch (_) {
      await KaraokeFiles.instance.deleteIfExists(outputPath);
      rethrow;
    }
    return MixOutput(outputPath, isVideo: withVideo);
  }

  /// Stops one running render; [render] then throws [cancelledMessage].
  static Future<void> cancelSession(int sessionId) => FFmpegKit.cancel(sessionId);

  static List<String> _audioCodec(ExportFormat format) => switch (format) {
        ExportFormat.m4a => ['-c:a', 'aac', '-b:a', '192k'],
        ExportFormat.mp3 => ['-c:a', 'libmp3lame', '-b:a', '192k'],
        ExportFormat.wav => ['-c:a', 'pcm_s16le'],
      };

  /// A render only counts when the file has the expected streams and length.
  static Future<void> _validate(String path,
      {required int expectedMs, required bool requireVideo}) async {
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      throw const KaraokeException('Mixing produced an empty file. Please try again.');
    }
    final info = (await FFprobeKit.getMediaInformation(path)).getMediaInformation();
    final streams = info?.getStreams() ?? const [];
    final hasAudio = streams.any((s) => s.getType() == 'audio');
    final hasVideo = streams.any((s) => s.getType() == 'video');
    final seconds = double.tryParse(info?.getDuration() ?? '');
    if (!hasAudio || (requireVideo && !hasVideo)) {
      throw const KaraokeException('The mixed file is missing audio or video.');
    }
    if (seconds != null) {
      final diff = (seconds * 1000 - expectedMs).abs();
      if (diff > 1500) {
        debugPrint('Mix length ${seconds}s, expected ${expectedMs / 1000}s');
        throw const KaraokeException('The mix came out the wrong length. Please try again.');
      }
    }
  }
}
