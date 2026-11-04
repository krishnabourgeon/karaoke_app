import 'dart:convert';

enum ReverbType { none, room, studio, hall }

enum ExportFormat { m4a, mp3, wav }

extension ExportFormatInfo on ExportFormat {
  String get extension => switch (this) {
        ExportFormat.m4a => '.m4a',
        ExportFormat.mp3 => '.mp3',
        ExportFormat.wav => '.wav',
      };

  String get label => switch (this) {
        ExportFormat.m4a => 'M4A (AAC)',
        ExportFormat.mp3 => 'MP3',
        ExportFormat.wav => 'WAV (lossless)',
      };
}

/// Everything the user can change in the Mix Studio. The recorded vocals are
/// never touched: these settings are applied each time a mix is rendered.
///
/// Timing convention: a positive [offsetMs] DELAYS the vocals relative to the
/// music, a negative one moves them earlier.
class MixSettings {
  static const double musicMax = 1.0; // UI 0–100 %
  static const double vocalMax = 1.5; // UI 0–150 %
  static const int offsetLimitMs = 500;
  static const double eqLimitDb = 12;

  final String presetId;
  final double musicVolume;
  final double vocalVolume;
  final bool muteMusic;
  final bool muteVocals;
  final int offsetMs;

  /// Cut from the start / end of the finished song (song timeline).
  final int trimStartMs;
  final int trimEndMs;

  final double noiseReduction; // 0..1
  final double bassDb; // -12..12
  final double midDb;
  final double trebleDb;
  final double compression; // 0..1, 0 = off
  final ReverbType reverb;
  final double reverbAmount; // 0..1
  final double echoAmount; // 0..1, 0 = off
  final int echoDelayMs; // 120..800

  const MixSettings({
    this.presetId = 'balanced',
    this.musicVolume = 0.8,
    this.vocalVolume = 1.0,
    this.muteMusic = false,
    this.muteVocals = false,
    this.offsetMs = 0,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.noiseReduction = 0.3,
    this.bassDb = 0,
    this.midDb = 0,
    this.trebleDb = 0,
    this.compression = 0.5,
    this.reverb = ReverbType.none,
    this.reverbAmount = 0,
    this.echoAmount = 0,
    this.echoDelayMs = 300,
  });

  static const MixSettings defaults = MixSettings();

  /// Same levels, timing and trims, but no processing: the "Before" in A/B.
  MixSettings get dry => copyWith(
        noiseReduction: 0,
        bassDb: 0,
        midDb: 0,
        trebleDb: 0,
        compression: 0,
        reverb: ReverbType.none,
        reverbAmount: 0,
        echoAmount: 0,
      );

  /// Applies [preset]'s sound but keeps this take's timing and trims.
  MixSettings withPreset(MixPreset preset) => preset.settings.copyWith(
        offsetMs: offsetMs,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        muteMusic: muteMusic,
        muteVocals: muteVocals,
      );

  MixSettings copyWith({
    String? presetId,
    double? musicVolume,
    double? vocalVolume,
    bool? muteMusic,
    bool? muteVocals,
    int? offsetMs,
    int? trimStartMs,
    int? trimEndMs,
    double? noiseReduction,
    double? bassDb,
    double? midDb,
    double? trebleDb,
    double? compression,
    ReverbType? reverb,
    double? reverbAmount,
    double? echoAmount,
    int? echoDelayMs,
  }) =>
      MixSettings(
        presetId: presetId ?? this.presetId,
        musicVolume: (musicVolume ?? this.musicVolume).clamp(0.0, musicMax),
        vocalVolume: (vocalVolume ?? this.vocalVolume).clamp(0.0, vocalMax),
        muteMusic: muteMusic ?? this.muteMusic,
        muteVocals: muteVocals ?? this.muteVocals,
        offsetMs: (offsetMs ?? this.offsetMs).clamp(-offsetLimitMs, offsetLimitMs),
        trimStartMs: (trimStartMs ?? this.trimStartMs).clamp(0, 1 << 30),
        trimEndMs: (trimEndMs ?? this.trimEndMs).clamp(0, 1 << 30),
        noiseReduction: (noiseReduction ?? this.noiseReduction).clamp(0.0, 1.0),
        bassDb: (bassDb ?? this.bassDb).clamp(-eqLimitDb, eqLimitDb),
        midDb: (midDb ?? this.midDb).clamp(-eqLimitDb, eqLimitDb),
        trebleDb: (trebleDb ?? this.trebleDb).clamp(-eqLimitDb, eqLimitDb),
        compression: (compression ?? this.compression).clamp(0.0, 1.0),
        reverb: reverb ?? this.reverb,
        reverbAmount: (reverbAmount ?? this.reverbAmount).clamp(0.0, 1.0),
        echoAmount: (echoAmount ?? this.echoAmount).clamp(0.0, 1.0),
        echoDelayMs: (echoDelayMs ?? this.echoDelayMs).clamp(120, 800),
      );

  Map<String, dynamic> toJson() => {
        'presetId': presetId,
        'musicVolume': musicVolume,
        'vocalVolume': vocalVolume,
        'muteMusic': muteMusic,
        'muteVocals': muteVocals,
        'offsetMs': offsetMs,
        'trimStartMs': trimStartMs,
        'trimEndMs': trimEndMs,
        'noiseReduction': noiseReduction,
        'bassDb': bassDb,
        'midDb': midDb,
        'trebleDb': trebleDb,
        'compression': compression,
        'reverb': reverb.name,
        'reverbAmount': reverbAmount,
        'echoAmount': echoAmount,
        'echoDelayMs': echoDelayMs,
      };

  factory MixSettings.fromJson(Map<String, dynamic> m) {
    double d(String k, double fallback) => (m[k] as num?)?.toDouble() ?? fallback;
    int i(String k, int fallback) => (m[k] as num?)?.toInt() ?? fallback;
    const x = MixSettings.defaults;
    return const MixSettings().copyWith(
      presetId: m['presetId'] as String? ?? x.presetId,
      musicVolume: d('musicVolume', x.musicVolume),
      vocalVolume: d('vocalVolume', x.vocalVolume),
      muteMusic: m['muteMusic'] as bool? ?? false,
      muteVocals: m['muteVocals'] as bool? ?? false,
      offsetMs: i('offsetMs', 0),
      trimStartMs: i('trimStartMs', 0),
      trimEndMs: i('trimEndMs', 0),
      noiseReduction: d('noiseReduction', x.noiseReduction),
      bassDb: d('bassDb', 0),
      midDb: d('midDb', 0),
      trebleDb: d('trebleDb', 0),
      compression: d('compression', x.compression),
      reverb: ReverbType.values.asNameMap()[m['reverb']] ?? ReverbType.none,
      reverbAmount: d('reverbAmount', 0),
      echoAmount: d('echoAmount', 0),
      echoDelayMs: i('echoDelayMs', x.echoDelayMs),
    );
  }

  /// Stable across app launches (unlike String.hashCode), so it can name
  /// cached renders: a different hash always means a different file.
  String get hash => fnv1a(jsonEncode(toJson()));

  @override
  bool operator ==(Object other) =>
      other is MixSettings && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => hash.hashCode;
}

/// 32-bit FNV-1a as 8 hex characters.
String fnv1a(String input) {
  var h = 0x811c9dc5;
  for (final unit in utf8.encode(input)) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

class MixPreset {
  final String id;
  final String name;
  final MixSettings settings;
  const MixPreset(this.id, this.name, this.settings);
}

const List<MixPreset> kMixPresets = [
  MixPreset('original', 'Original', MixSettings(
    presetId: 'original', noiseReduction: 0, compression: 0)),
  MixPreset('balanced', 'Balanced Karaoke', MixSettings()),
  MixPreset('clear', 'Clear Vocals', MixSettings(
    presetId: 'clear', musicVolume: 0.7, vocalVolume: 1.1, noiseReduction: 0.4,
    bassDb: -2, midDb: 2, trebleDb: 3, compression: 0.6)),
  MixPreset('studio', 'Studio Vocal', MixSettings(
    presetId: 'studio', noiseReduction: 0.4, midDb: 1, trebleDb: 2,
    compression: 0.7, reverb: ReverbType.studio, reverbAmount: 0.35)),
  MixPreset('warm', 'Warm Vocal', MixSettings(
    presetId: 'warm', noiseReduction: 0.3, bassDb: 3, midDb: 0, trebleDb: -2,
    compression: 0.5, reverb: ReverbType.room, reverbAmount: 0.25)),
  MixPreset('hall', 'Concert Hall', MixSettings(
    presetId: 'hall', noiseReduction: 0.3, trebleDb: 1, compression: 0.5,
    reverb: ReverbType.hall, reverbAmount: 0.5)),
  MixPreset('focus', 'Voice Focus', MixSettings(
    presetId: 'focus', musicVolume: 0.55, vocalVolume: 1.2, noiseReduction: 0.5,
    bassDb: -3, midDb: 3, trebleDb: 1, compression: 0.8)),
];
