// import 'dart:math' as math;

// import 'package:karaoke_app/model/mix_settings.dart';

// /// Builds the FFmpeg filter graph for a mix. Pure string building, so every
// /// preset can be unit tested without running FFmpeg.
// ///
// /// Input 0 is the music, input 1 the vocals. The output label is [out].
// ///
// /// Processing order (all built-in FFmpeg filters, available in
// /// ffmpeg_kit_flutter_new_audio):
// ///   vocals: format → highpass (rumble) → afftdn (noise reduction) → adelay
// ///           (timing) → bass / equalizer / treble (EQ) → acompressor →
// ///           aecho (reverb taps) → aecho (echo) → volume
// ///   music:  format → volume
// ///   master: amix (no normalisation) → alimiter (peak ceiling ≈ −1 dBFS)
// ///
// /// Reverb is an early-reflection approximation made with aecho taps; FFmpeg
// /// has no algorithmic reverb. Swapping in `afir` with bundled impulse
// /// responses would sound more natural.
// class AudioEffectsProcessor {
//   AudioEffectsProcessor._();

//   /// Gain at 100 % on the sliders. Phone-mic vocals are much quieter than a
//   /// mastered backing track, so the voice gets more gain than the music.
//   static const double musicUnityGain = 0.7;
//   static const double vocalUnityGain = 1.8;

//   /// Output peak ceiling (linear). 0.89 ≈ −1 dBFS, headroom for AAC/MP3.
//   static const double limiterCeiling = 0.89;

//   static const String _format = 'aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo';

//   static String buildFilterGraph(MixSettings s, {int vocalDelayMs = 0}) {
//     final musicGain = s.muteMusic ? 0.0 : s.musicVolume * musicUnityGain;
//     final vocalGain = s.muteVocals ? 0.0 : s.vocalVolume * vocalUnityGain;

//     final music = '[0:a]aresample=44100,$_format,volume=${_n(musicGain)}[m]';
//     final vocals = '[1:a]aresample=44100,$_format,'
//         '${vocalChain(s, vocalDelayMs: vocalDelayMs).join(',')},'
//         'volume=${_n(vocalGain)}[v]';
//     final master = '[m][v]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,'
//         'alimiter=limit=$limiterCeiling:attack=5:release=50:level=0[out]';
//     return '$music;$vocals;$master';
//   }

//   /// The vocal effect filters in processing order (without the final volume).
//   static List<String> vocalChain(MixSettings s, {int vocalDelayMs = 0}) => [
//         'highpass=f=80',
//         if (s.noiseReduction > 0)
//           // nr is in dB; 4–16 dB keeps the voice natural. This reduces steady
//           // hiss and fan noise; it does not remove background sounds.
//           'afftdn=nr=${_n(4 + 12 * s.noiseReduction)}:nf=-50:tn=1',
//         if (vocalDelayMs > 0) 'adelay=$vocalDelayMs:all=1',
//         if (s.bassDb != 0) 'bass=g=${_n(s.bassDb)}:f=120:w=0.7',
//         if (s.midDb != 0) 'equalizer=f=1500:t=q:w=1:g=${_n(s.midDb)}',
//         if (s.trebleDb != 0) 'treble=g=${_n(s.trebleDb)}:f=6000:w=0.7',
//         if (s.compression > 0) _compressor(s.compression),
//         if (s.reverb != ReverbType.none && s.reverbAmount > 0)
//           _reverb(s.reverb, s.reverbAmount),
//         if (s.echoAmount > 0)
//           'aecho=1:0.9:${s.echoDelayMs}:${_n(0.05 + 0.45 * s.echoAmount)}',
//       ];

//   /// Intensity 0..1 → gentle (ratio 2) up to firm (ratio 6) compression.
//   /// At 0.5 this matches the app's original vocal settings.
//   static String _compressor(double c) {
//     final ratio = 1.5 + 4.5 * c;
//     final thresholdDb = -12 - 12 * c;
//     final threshold = _dbToLinear(thresholdDb);
//     final makeup = 1 + 3 * c;
//     return 'acompressor=threshold=${_n(threshold, 4)}:ratio=${_n(ratio)}'
//         ':attack=10:release=200:makeup=${_n(makeup)}';
//   }

//   static String _reverb(ReverbType type, double amount) {
//     final (delays, decays) = switch (type) {
//       ReverbType.room => (const [23, 41, 67], const [0.35, 0.25, 0.18]),
//       ReverbType.studio => (const [35, 60, 95, 130], const [0.32, 0.24, 0.17, 0.11]),
//       ReverbType.hall => (const [60, 120, 190, 280, 390], const [0.42, 0.34, 0.26, 0.19, 0.12]),
//       ReverbType.none => (const <int>[], const <double>[]),
//     };
//     final scaled = [
//       for (final d in decays) (d * amount * 1.6).clamp(0.01, 0.9),
//     ];
//     return 'aecho=1:0.85:${delays.join('|')}:${scaled.map((d) => _n(d)).join('|')}';
//   }

//   static double _dbToLinear(double db) => math.pow(10, db / 20).toDouble();

//   static String _n(double v, [int digits = 2]) => v.toStringAsFixed(digits);
// }







import 'dart:math' as math;

import 'package:karaoke_app/model/mix_settings.dart';

/// Builds the FFmpeg filter graph for a mix. Pure string building, so every
/// preset can be unit tested without running FFmpeg.
///
/// Input 0 is the music, input 1 the vocals. The output label is [out].
///
/// Processing order (all built-in FFmpeg filters, available in
/// ffmpeg_kit_flutter_new_audio):
///   vocals: format → highpass (rumble) → afftdn (noise reduction) → adelay
///           (timing) → bass / equalizer / treble (EQ) → acompressor →
///           aecho (reverb taps) → aecho (echo) → volume
///   music:  format → volume
///   master: amix (no normalisation) → alimiter (peak ceiling ≈ −1 dBFS)
///
/// Reverb is an early-reflection approximation made with aecho taps; FFmpeg
/// has no algorithmic reverb. Swapping in `afir` with bundled impulse
/// responses would sound more natural.
class AudioEffectsProcessor {
  AudioEffectsProcessor._();

  /// Gain at 100 % on the sliders. Phone-mic vocals are much quieter than a
  /// mastered backing track, so the voice gets more gain than the music.
  static const double musicUnityGain = 0.7;
  static const double vocalUnityGain = 1.8;

  /// Output peak ceiling (linear). 0.89 ≈ −1 dBFS, headroom for AAC/MP3.
  static const double limiterCeiling = 0.89;

  static const String _format = 'aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo';

  static String buildFilterGraph(MixSettings s, {int vocalDelayMs = 0}) {
    final musicGain = s.muteMusic ? 0.0 : s.musicVolume * musicUnityGain;
    final vocalGain = s.muteVocals ? 0.0 : s.vocalVolume * vocalUnityGain;

    final music = '[0:a]aresample=44100,$_format,volume=${_n(musicGain)}[m]';
    final vocals = '[1:a]aresample=44100,$_format,'
        '${vocalChain(s, vocalDelayMs: vocalDelayMs).join(',')},'
        'volume=${_n(vocalGain)}[v]';
    final master = '[m][v]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,'
        'alimiter=limit=$limiterCeiling:attack=5:release=50:level=0[out]';
    return '$music;$vocals;$master';
  }

  /// The vocal effect filters in processing order (without the final volume).
  static List<String> vocalChain(MixSettings s, {int vocalDelayMs = 0}) => [
        'highpass=f=80',
        if (s.noiseReduction > 0)
          // nr is in dB; 4–16 dB keeps the voice natural. This reduces steady
          // hiss and fan noise; it does not remove background sounds.
          'afftdn=nr=${_n(4 + 12 * s.noiseReduction)}:nf=-50:tn=1',
        if (vocalDelayMs > 0) 'adelay=$vocalDelayMs:all=1',
        if (s.bassDb != 0) 'bass=g=${_n(s.bassDb)}:f=120:w=0.7',
        if (s.midDb != 0) 'equalizer=f=1500:t=q:w=1:g=${_n(s.midDb)}',
        if (s.trebleDb != 0) 'treble=g=${_n(s.trebleDb)}:f=6000:w=0.7',
        if (s.compression > 0) _compressor(s.compression),
        if (s.reverb != ReverbType.none && s.reverbAmount > 0)
          _reverb(s.reverb, s.reverbAmount),
        if (s.echoAmount > 0)
          'aecho=1:0.9:${s.echoDelayMs}:${_n(0.05 + 0.45 * s.echoAmount)}',
      ];

  /// Intensity 0..1 → gentle (ratio 2) up to firm (ratio 6) compression.
  /// At 0.5 this matches the app's original vocal settings.
  static String _compressor(double c) {
    final ratio = 1.5 + 4.5 * c;
    final thresholdDb = -12 - 12 * c;
    final threshold = _dbToLinear(thresholdDb);
    final makeup = 1 + 3 * c;
    return 'acompressor=threshold=${_n(threshold, 4)}:ratio=${_n(ratio)}'
        ':attack=10:release=200:makeup=${_n(makeup)}';
  }

  static String _reverb(ReverbType type, double amount) {
    final (delays, decays) = switch (type) {
      ReverbType.room => (const [23, 41, 67], const [0.35, 0.25, 0.18]),
      ReverbType.studio => (const [35, 60, 95, 130], const [0.32, 0.24, 0.17, 0.11]),
      ReverbType.hall => (const [60, 120, 190, 280, 390], const [0.42, 0.34, 0.26, 0.19, 0.12]),
      ReverbType.none => (const <int>[], const <double>[]),
    };
    final scaled = [
      for (final d in decays) (d * amount * 1.6).clamp(0.01, 0.9),
    ];
    return 'aecho=1:0.85:${delays.join('|')}:${scaled.map((d) => _n(d)).join('|')}';
  }

  static double _dbToLinear(double db) => math.pow(10, db / 20).toDouble();

  static String _n(double v, [int digits = 2]) => v.toStringAsFixed(digits);
}
