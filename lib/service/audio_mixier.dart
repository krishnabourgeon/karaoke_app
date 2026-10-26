import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_audio/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:karaoke_app/service/karaoke_files.dart';

class MixOutput {
  final String path;
  final bool isVideo;
  const MixOutput(this.path, {required this.isVideo});
}

class AudioMixer {
  AudioMixer._();

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

  /// Mixes [backingPath] (music) and [vocalsPath] (mic) into one file.
  ///
  /// [vocalShift] > 0 removes that much from the start of the vocals (the mic
  /// was running before the music started); < 0 delays the vocals instead.
  /// With [videoPath], the result is an mp4 with the original picture.
  static Future<MixOutput> mix({
    required String backingPath,
    required String vocalsPath,
    required Duration vocalShift,
    String? videoPath,
    double musicVolume = 0.55,
    double voiceVolume = 1.8,
    Duration? expectedLength,
    void Function(double progress)? onProgress,
  }) async {
    if (!await File(vocalsPath).exists()) {
      throw const KaraokeException('Your recording is missing. Please record again.');
    }
    if (!await File(backingPath).exists()) {
      throw const KaraokeException('The karaoke track is missing. Reopen the song and try again.');
    }

    if (videoPath != null && await File(videoPath).exists()) {
      try {
        return await _run(backingPath, vocalsPath, vocalShift, videoPath,
            musicVolume, voiceVolume, expectedLength, onProgress);
      } on KaraokeException catch (e) {
        if (e.message == _cancelled) rethrow;
        debugPrint('Video mix failed, falling back to audio only.');
      }
    }
    return _run(backingPath, vocalsPath, vocalShift, null,
        musicVolume, voiceVolume, expectedLength, onProgress);
  }

  /// Stops a running mix; [mix] then throws "Mixing was cancelled."
  static Future<void> cancel() => FFmpegKit.cancel();

  static const _cancelled = 'Mixing was cancelled.';

  static Future<MixOutput> _run(
    String backingPath,
    String vocalsPath,
    Duration vocalShift,
    String? videoPath,
    double musicVolume,
    double voiceVolume,
    Duration? expectedLength,
    void Function(double progress)? onProgress,
  ) async {
    final withVideo = videoPath != null;
    final out = await KaraokeFiles.instance.newMixPath(video: withVideo);
    final shiftMs = vocalShift.inMilliseconds;
    const fmt = 'aformat=sample_rates=44100:channel_layouts=stereo';
    final delay = shiftMs < 0 ? 'adelay=${-shiftMs}:all=1,' : '';

    // Vocal chain: cut low rumble, then compress and lift the voice so quiet
    // phone-mic singing sits clearly on top of the music.
    const voiceBoost =
        'highpass=f=80,'
        'acompressor=threshold=0.125:ratio=3:attack=10:release=200:makeup=2.5,';

    final filter =
        '[0:a]$fmt,volume=${musicVolume.toStringAsFixed(2)}[m];'
        '[1:a]$fmt,$voiceBoost${delay}volume=${voiceVolume.toStringAsFixed(2)}[v];'
        '[m][v]amix=inputs=2:duration=shortest:dropout_transition=0:normalize=0,'
        'alimiter=limit=0.95[out]';

    final args = <String>[
      '-y',
      '-i', backingPath,
      if (shiftMs > 0) ...['-ss', (shiftMs / 1000).toStringAsFixed(3)],
      '-i', vocalsPath,
      if (withVideo) ...['-i', videoPath],
      '-filter_complex', filter,
      '-map', '[out]',
      if (withVideo) ...['-map', '2:v:0', '-c:v', 'copy', '-shortest'],
      '-c:a', 'aac', '-b:a', '192k',
      '-movflags', '+faststart',
      out,
    ];

    final done = Completer<void>();
    final totalMs = expectedLength?.inMilliseconds ?? 0;

    await FFmpegKit.executeWithArgumentsAsync(
      args,
      (FFmpegSession session) async {
        final code = await session.getReturnCode();
        if (ReturnCode.isSuccess(code)) {
          done.complete();
        } else if (ReturnCode.isCancel(code)) {
          done.completeError(const KaraokeException(_cancelled));
        } else {
          debugPrint('FFmpeg mix failed ($code):\n${await session.getAllLogsAsString()}');
          done.completeError(const KaraokeException('Mixing failed. Please try again.'));
        }
      },
      null,
      (Statistics stats) {
        if (totalMs > 0) onProgress?.call((stats.getTime() / totalMs).clamp(0.0, 1.0));
      },
    );

    try {
      await done.future;
    } catch (_) {
      await KaraokeFiles.instance.deleteIfExists(out);
      rethrow;
    }

    final file = File(out);
    if (!await file.exists() || await file.length() == 0) {
      throw const KaraokeException('Mixing produced an empty file. Please try again.');
    }
    return MixOutput(out, isVideo: withVideo);
  }
}