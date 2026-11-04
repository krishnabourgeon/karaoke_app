// import 'package:karaoke_app/model/mix_settings.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';

// /// A finished mix of a take. [settingsHash] says which settings made it.
// class MixRender {
//   final String file; // file name inside docs/karaoke/mixes
//   final ExportFormat format;
//   final bool isVideo;
//   final String settingsHash;
//   final DateTime createdAt;

//   const MixRender({
//     required this.file,
//     required this.format,
//     required this.isVideo,
//     required this.settingsHash,
//     required this.createdAt,
//   });

//   Map<String, dynamic> toJson() => {
//         'file': file,
//         'format': format.name,
//         'isVideo': isVideo,
//         'settingsHash': settingsHash,
//         'createdAt': createdAt.millisecondsSinceEpoch,
//       };

//   factory MixRender.fromJson(Map<String, dynamic> m) => MixRender(
//         file: m['file'] as String,
//         format: ExportFormat.values.asNameMap()[m['format']] ?? ExportFormat.m4a,
//         isVideo: m['isVideo'] as bool? ?? false,
//         settingsHash: m['settingsHash'] as String? ?? '',
//         createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int? ?? 0),
//       );
// }

// /// One recorded vocal take, kept so it can be mixed again at any time.
// ///
// /// Only file names are stored, because the documents folder path can change
// /// between app launches on iOS. [RecordingsStore] turns them into paths.
// class RecordingTake {
//   final String id;
//   final String title;
//   final Track track; // the karaoke the user sang over
//   final String vocalsFile; // file name inside docs/karaoke/vocals
//   final Duration length; // how long the mic ran
//   final Duration musicOffset; // mic time before the music started
//   final bool interrupted;
//   final DateTime createdAt;
//   final MixSettings settings;
//   final List<MixRender> renders;

//   const RecordingTake({
//     required this.id,
//     required this.title,
//     required this.track,
//     required this.vocalsFile,
//     required this.length,
//     required this.musicOffset,
//     required this.interrupted,
//     required this.createdAt,
//     this.settings = MixSettings.defaults,
//     this.renders = const [],
//   });

//   /// Length of the finished song with the vocals unshifted.
//   Duration get songLength {
//     final d = length - musicOffset;
//     return d.isNegative ? Duration.zero : d;
//   }

//   /// The newest render made with exactly [s], if any.
//   MixRender? renderFor(MixSettings s, {ExportFormat? format}) {
//     final hash = s.hash;
//     for (final r in renders.reversed) {
//       if (r.settingsHash == hash && (format == null || r.format == format)) return r;
//     }
//     return null;
//   }

//   RecordingTake copyWith({
//     String? title,
//     MixSettings? settings,
//     List<MixRender>? renders,
//   }) =>
//       RecordingTake(
//         id: id,
//         title: title ?? this.title,
//         track: track,
//         vocalsFile: vocalsFile,
//         length: length,
//         musicOffset: musicOffset,
//         interrupted: interrupted,
//         createdAt: createdAt,
//         settings: settings ?? this.settings,
//         renders: renders ?? this.renders,
//       );

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'title': title,
//         'track': track.toJson(),
//         'vocalsFile': vocalsFile,
//         'lengthMs': length.inMilliseconds,
//         'musicOffsetMs': musicOffset.inMilliseconds,
//         'interrupted': interrupted,
//         'createdAt': createdAt.millisecondsSinceEpoch,
//         'settings': settings.toJson(),
//         'renders': [for (final r in renders) r.toJson()],
//       };

//   factory RecordingTake.fromJson(Map<String, dynamic> m) => RecordingTake(
//         id: m['id'] as String,
//         title: m['title'] as String,
//         track: Track.fromJson((m['track'] as Map).cast<String, dynamic>()),
//         vocalsFile: m['vocalsFile'] as String,
//         length: Duration(milliseconds: m['lengthMs'] as int),
//         musicOffset: Duration(milliseconds: m['musicOffsetMs'] as int? ?? 0),
//         interrupted: m['interrupted'] as bool? ?? false,
//         createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
//         settings: m['settings'] is Map
//             ? MixSettings.fromJson((m['settings'] as Map).cast<String, dynamic>())
//             : MixSettings.defaults,
//         renders: [
//           for (final r in (m['renders'] as List? ?? const []))
//             MixRender.fromJson((r as Map).cast<String, dynamic>()),
//         ],
//       );
// }




import 'package:karaoke_app/model/mix_settings.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';

/// A finished mix of a take. [settingsHash] says which settings made it.
class MixRender {
  final String file; // file name inside docs/karaoke/mixes
  final ExportFormat format;
  final bool isVideo;
  final String settingsHash;
  final DateTime createdAt;

  const MixRender({
    required this.file,
    required this.format,
    required this.isVideo,
    required this.settingsHash,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'file': file,
        'format': format.name,
        'isVideo': isVideo,
        'settingsHash': settingsHash,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory MixRender.fromJson(Map<String, dynamic> m) => MixRender(
        file: m['file'] as String,
        format: ExportFormat.values.asNameMap()[m['format']] ?? ExportFormat.m4a,
        isVideo: m['isVideo'] as bool? ?? false,
        settingsHash: m['settingsHash'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int? ?? 0),
      );
}

/// One recorded vocal take, kept so it can be mixed again at any time.
///
/// Only file names are stored, because the documents folder path can change
/// between app launches on iOS. [RecordingsStore] turns them into paths.
class RecordingTake {
  final String id;
  final String title;
  final Track track; // the karaoke the user sang over
  final String vocalsFile; // file name inside docs/karaoke/vocals
  final Duration length; // how long the mic ran
  final Duration musicOffset; // mic time before the music started
  final bool interrupted;
  final DateTime createdAt;
  final MixSettings settings;
  final List<MixRender> renders;

  const RecordingTake({
    required this.id,
    required this.title,
    required this.track,
    required this.vocalsFile,
    required this.length,
    required this.musicOffset,
    required this.interrupted,
    required this.createdAt,
    this.settings = MixSettings.defaults,
    this.renders = const [],
  });

  /// Length of the finished song with the vocals unshifted.
  Duration get songLength {
    final d = length - musicOffset;
    return d.isNegative ? Duration.zero : d;
  }

  /// The newest render made with exactly [s], if any.
  MixRender? renderFor(MixSettings s, {ExportFormat? format}) {
    final hash = s.hash;
    for (final r in renders.reversed) {
      if (r.settingsHash == hash && (format == null || r.format == format)) return r;
    }
    return null;
  }

  RecordingTake copyWith({
    String? title,
    MixSettings? settings,
    List<MixRender>? renders,
  }) =>
      RecordingTake(
        id: id,
        title: title ?? this.title,
        track: track,
        vocalsFile: vocalsFile,
        length: length,
        musicOffset: musicOffset,
        interrupted: interrupted,
        createdAt: createdAt,
        settings: settings ?? this.settings,
        renders: renders ?? this.renders,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'track': track.toJson(),
        'vocalsFile': vocalsFile,
        'lengthMs': length.inMilliseconds,
        'musicOffsetMs': musicOffset.inMilliseconds,
        'interrupted': interrupted,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'settings': settings.toJson(),
        'renders': [for (final r in renders) r.toJson()],
      };

  factory RecordingTake.fromJson(Map<String, dynamic> m) => RecordingTake(
        id: m['id'] as String,
        title: m['title'] as String,
        track: Track.fromJson((m['track'] as Map).cast<String, dynamic>()),
        vocalsFile: m['vocalsFile'] as String,
        length: Duration(milliseconds: m['lengthMs'] as int),
        musicOffset: Duration(milliseconds: m['musicOffsetMs'] as int? ?? 0),
        interrupted: m['interrupted'] as bool? ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        settings: m['settings'] is Map
            ? MixSettings.fromJson((m['settings'] as Map).cast<String, dynamic>())
            : MixSettings.defaults,
        renders: [
          for (final r in (m['renders'] as List? ?? const []))
            MixRender.fromJson((r as Map).cast<String, dynamic>()),
        ],
      );
}
