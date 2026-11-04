// import 'dart:io';
// import 'dart:isolate';

// import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
// import 'package:flutter/foundation.dart';
// import 'package:karaoke_app/model/mix_settings.dart';
// import 'package:karaoke_app/service/karaoke_files.dart';

// /// Peaks for drawing a waveform: one value 0..1 per bucket, spread evenly
// /// over [duration].
// class Waveform {
//   final Float32List peaks;
//   final Duration duration;
//   const Waveform(this.peaks, this.duration);
// }

// /// Makes small waveform summaries without loading whole songs into memory:
// /// FFmpeg decodes to 2 kHz mono PCM (~1 MB for 4 minutes), an isolate
// /// reduces it to [buckets] peaks, the PCM is deleted and the peaks cached.
// class WaveformService {
//   WaveformService._();
//   static final WaveformService instance = WaveformService._();

//   static const int _rate = 2000;
//   static const int buckets = 1200;

//   Future<Waveform?> load(String audioPath) async {
//     final source = File(audioPath);
//     if (!await source.exists()) return null;
//     final stat = await source.stat();
//     final key = fnv1a('$audioPath|${stat.size}|${stat.modified.millisecondsSinceEpoch}');
//     final dir = await KaraokeFiles.instance.folder('peaks', cache: true);
//     final cached = File('${dir.path}/$key.peaks');

//     try {
//       if (await cached.exists()) return _decode(await cached.readAsBytes());

//       final pcm = '${dir.path}/$key.pcm';
//       final session = await FFmpegKit.executeWithArguments([
//         '-y', '-i', audioPath, '-vn',
//         '-ac', '1', '-ar', '$_rate', '-f', 's16le', '-acodec', 'pcm_s16le',
//         pcm,
//       ]);
//       if (!ReturnCode.isSuccess(await session.getReturnCode())) {
//         debugPrint('Waveform decode failed for ${source.uri.pathSegments.last}');
//         await KaraokeFiles.instance.deleteIfExists(pcm);
//         return null;
//       }
//       final bytes = await Isolate.run(() => _summarise(pcm, buckets));
//       await KaraokeFiles.instance.deleteIfExists(pcm);
//       await cached.writeAsBytes(bytes, flush: true);
//       return _decode(bytes);
//     } catch (e) {
//       debugPrint('Waveform failed: $e');
//       return null;
//     }
//   }

//   /// Layout: [int32 sample count][float32 peaks...]
//   static Waveform _decode(Uint8List bytes) {
//     final data = ByteData.sublistView(bytes);
//     final samples = data.getInt32(0, Endian.little);
//     final peaks = Float32List.sublistView(Uint8List.fromList(bytes.sublist(4)));
//     return Waveform(
//         peaks, Duration(milliseconds: (samples * 1000 / _rate).round()));
//   }

//   static Uint8List _summarise(String pcmPath, int buckets) {
//     final raw = File(pcmPath).readAsBytesSync();
//     final samples = ByteData.sublistView(raw);
//     final count = raw.length ~/ 2;
//     final peaks = Float32List(buckets);
//     if (count > 0) {
//       final per = count / buckets;
//       var maxPeak = 1e-6;
//       for (var b = 0; b < buckets; b++) {
//         final from = (b * per).floor();
//         final to = ((b + 1) * per).ceil().clamp(from + 1, count);
//         var peak = 0;
//         for (var i = from; i < to; i++) {
//           final v = samples.getInt16(i * 2, Endian.little).abs();
//           if (v > peak) peak = v;
//         }
//         peaks[b] = peak / 32768;
//         if (peaks[b] > maxPeak) maxPeak = peaks[b];
//       }
//       // Normalise so quiet phone vocals are still visible.
//       for (var b = 0; b < buckets; b++) {
//         peaks[b] = peaks[b] / maxPeak;
//       }
//     }
//     final out = ByteData(4 + buckets * 4)..setInt32(0, count, Endian.little);
//     for (var b = 0; b < buckets; b++) {
//       out.setFloat32(4 + b * 4, peaks[b], Endian.little);
//     }
//     return out.buffer.asUint8List();
//   }
// }




import 'dart:io';
import 'dart:isolate';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:karaoke_app/model/mix_settings.dart';
import 'package:karaoke_app/service/karaoke_files.dart';

/// Peaks for drawing a waveform: one value 0..1 per bucket, spread evenly
/// over [duration].
class Waveform {
  final Float32List peaks;
  final Duration duration;
  const Waveform(this.peaks, this.duration);
}

/// Makes small waveform summaries without loading whole songs into memory:
/// FFmpeg decodes to 2 kHz mono PCM (~1 MB for 4 minutes), an isolate
/// reduces it to [buckets] peaks, the PCM is deleted and the peaks cached.
class WaveformService {
  WaveformService._();
  static final WaveformService instance = WaveformService._();

  static const int _rate = 2000;
  static const int buckets = 1200;

  Future<Waveform?> load(String audioPath) async {
    final source = File(audioPath);
    if (!await source.exists()) return null;
    final stat = await source.stat();
    final key = fnv1a('$audioPath|${stat.size}|${stat.modified.millisecondsSinceEpoch}');
    final dir = await KaraokeFiles.instance.folder('peaks', cache: true);
    final cached = File('${dir.path}/$key.peaks');

    try {
      if (await cached.exists()) return _decode(await cached.readAsBytes());

      final pcm = '${dir.path}/$key.pcm';
      final session = await FFmpegKit.executeWithArguments([
        '-y', '-i', audioPath, '-vn',
        '-ac', '1', '-ar', '$_rate', '-f', 's16le', '-acodec', 'pcm_s16le',
        pcm,
      ]);
      if (!ReturnCode.isSuccess(await session.getReturnCode())) {
        debugPrint('Waveform decode failed for ${source.uri.pathSegments.last}');
        await KaraokeFiles.instance.deleteIfExists(pcm);
        return null;
      }
      final bytes = await Isolate.run(() => _summarise(pcm, buckets));
      await KaraokeFiles.instance.deleteIfExists(pcm);
      await cached.writeAsBytes(bytes, flush: true);
      return _decode(bytes);
    } catch (e) {
      debugPrint('Waveform failed: $e');
      return null;
    }
  }

  /// Layout: [int32 sample count][float32 peaks...]
  static Waveform _decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final samples = data.getInt32(0, Endian.little);
    final peaks = Float32List.sublistView(Uint8List.fromList(bytes.sublist(4)));
    return Waveform(
        peaks, Duration(milliseconds: (samples * 1000 / _rate).round()));
  }

  static Uint8List _summarise(String pcmPath, int buckets) {
    final raw = File(pcmPath).readAsBytesSync();
    final samples = ByteData.sublistView(raw);
    final count = raw.length ~/ 2;
    final peaks = Float32List(buckets);
    if (count > 0) {
      final per = count / buckets;
      var maxPeak = 1e-6;
      for (var b = 0; b < buckets; b++) {
        final from = (b * per).floor();
        final to = ((b + 1) * per).ceil().clamp(from + 1, count);
        var peak = 0;
        for (var i = from; i < to; i++) {
          final v = samples.getInt16(i * 2, Endian.little).abs();
          if (v > peak) peak = v;
        }
        peaks[b] = peak / 32768;
        if (peaks[b] > maxPeak) maxPeak = peaks[b];
      }
      // Normalise so quiet phone vocals are still visible.
      for (var b = 0; b < buckets; b++) {
        peaks[b] = peaks[b] / maxPeak;
      }
    }
    final out = ByteData(4 + buckets * 4)..setInt32(0, count, Endian.little);
    for (var b = 0; b < buckets; b++) {
      out.setFloat32(4 + b * 4, peaks[b], Endian.little);
    }
    return out.buffer.asUint8List();
  }
}
