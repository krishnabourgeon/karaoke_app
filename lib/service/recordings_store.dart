// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/foundation.dart';
// import 'package:karaoke_app/model/mix_settings.dart';
// import 'package:karaoke_app/model/recording_take.dart';
// import 'package:karaoke_app/service/karaoke_files.dart';
// import 'package:karaoke_app/service/karaoke_recorder.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// /// The user's recorded takes and their mixes, saved on the device.
// ///
// /// Raw vocals live in docs/karaoke/vocals and finished mixes in
// /// docs/karaoke/mixes; they are never mixed into the same file.
// class RecordingsStore extends ChangeNotifier {
//   RecordingsStore._();
//   static final RecordingsStore instance = RecordingsStore._();

//   static const String _key = 'swaram_recordings';

//   SharedPreferences? _prefs;
//   late Directory _vocalsDir;
//   late Directory _mixesDir;
//   final List<RecordingTake> _takes = [];

//   /// Newest first.
//   List<RecordingTake> get takes => _takes.reversed.toList(growable: false);

//   RecordingTake? byId(String id) {
//     for (final t in _takes) {
//       if (t.id == id) return t;
//     }
//     return null;
//   }

//   String vocalsPath(RecordingTake take) => _join(_vocalsDir, take.vocalsFile);
//   String renderPath(MixRender render) => _join(_mixesDir, render.file);

//   /// Call once in main() before runApp.
//   Future<void> init() async {
//     _prefs = await SharedPreferences.getInstance();
//     _vocalsDir = await KaraokeFiles.instance.folder('vocals');
//     _mixesDir = await KaraokeFiles.instance.folder('mixes');

//     _takes.clear();
//     final raw = _prefs!.getString(_key);
//     if (raw != null) {
//       try {
//         for (final item in jsonDecode(raw) as List) {
//           final take = RecordingTake.fromJson((item as Map).cast<String, dynamic>());
//           // A take without its vocals cannot be mixed again.
//           if (!await File(vocalsPath(take)).exists()) continue;
//           final renders = <MixRender>[
//             for (final r in take.renders)
//               if (await File(renderPath(r)).exists()) r,
//           ];
//           _takes.add(take.copyWith(renders: renders));
//         }
//       } catch (e) {
//         debugPrint('Could not read saved recordings: $e');
//       }
//     }
//     unawaited(KaraokeFiles.instance.clearOldPreviews());
//   }

//   Future<RecordingTake> addTake(Track track, RecordingResult result) async {
//     final take = RecordingTake(
//       id: 'r${DateTime.now().millisecondsSinceEpoch}',
//       title: '${track.title} (My cover)',
//       track: track,
//       vocalsFile: _fileName(result.vocalsPath),
//       length: result.length,
//       musicOffset: result.musicOffset,
//       interrupted: result.interrupted,
//       createdAt: DateTime.now(),
//     );
//     _takes.add(take);
//     await _save();
//     notifyListeners();
//     return take;
//   }

//   Future<RecordingTake?> updateSettings(String id, MixSettings settings) =>
//       _update(id, (t) => t.copyWith(settings: settings));

//   Future<RecordingTake?> rename(String id, String title) {
//     final clean = title.trim();
//     if (clean.isEmpty) return Future.value(byId(id));
//     return _update(id, (t) => t.copyWith(title: clean));
//   }

//   /// Saves [render] for the take, keeping only the newest one per settings
//   /// and format, and deletes the file it replaces.
//   Future<RecordingTake?> addRender(String id, MixRender render) async {
//     final take = byId(id);
//     if (take == null) return null;
//     final keep = <MixRender>[];
//     for (final r in take.renders) {
//       if (r.settingsHash == render.settingsHash &&
//           r.format == render.format &&
//           r.isVideo == render.isVideo &&
//           r.file != render.file) {
//         await KaraokeFiles.instance.deleteIfExists(renderPath(r));
//       } else {
//         keep.add(r);
//       }
//     }
//     return _update(id, (t) => t.copyWith(renders: [...keep, render]));
//   }

//   /// Deletes the take, its raw vocals and every mix made from it.
//   Future<void> delete(String id) async {
//     final take = byId(id);
//     if (take == null) return;
//     _takes.removeWhere((t) => t.id == id);
//     await _save();
//     notifyListeners();
//     await KaraokeFiles.instance.deleteIfExists(vocalsPath(take));
//     for (final r in take.renders) {
//       await KaraokeFiles.instance.deleteIfExists(renderPath(r));
//     }
//   }

//   Future<RecordingTake?> _update(
//       String id, RecordingTake Function(RecordingTake) change) async {
//     final i = _takes.indexWhere((t) => t.id == id);
//     if (i == -1) return null;
//     _takes[i] = change(_takes[i]);
//     await _save();
//     notifyListeners();
//     return _takes[i];
//   }

//   Future<void> _save() async {
//     await _prefs?.setString(
//         _key, jsonEncode([for (final t in _takes) t.toJson()]));
//   }

//   String _join(Directory dir, String file) =>
//       '${dir.path}${Platform.pathSeparator}$file';

//   String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;
// }




import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:karaoke_app/model/mix_settings.dart';
import 'package:karaoke_app/model/recording_take.dart';
import 'package:karaoke_app/service/karaoke_files.dart';
import 'package:karaoke_app/service/karaoke_recorder.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's recorded takes and their mixes, saved on the device.
///
/// Raw vocals live in docs/karaoke/vocals and finished mixes in
/// docs/karaoke/mixes; they are never mixed into the same file.
class RecordingsStore extends ChangeNotifier {
  RecordingsStore._();
  static final RecordingsStore instance = RecordingsStore._();

  static const String _key = 'swaram_recordings';

  SharedPreferences? _prefs;
  late Directory _vocalsDir;
  late Directory _mixesDir;
  final List<RecordingTake> _takes = [];

  /// Newest first.
  List<RecordingTake> get takes => _takes.reversed.toList(growable: false);

  RecordingTake? byId(String id) {
    for (final t in _takes) {
      if (t.id == id) return t;
    }
    return null;
  }

  String vocalsPath(RecordingTake take) => _join(_vocalsDir, take.vocalsFile);
  String renderPath(MixRender render) => _join(_mixesDir, render.file);

  /// Call once in main() before runApp.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _vocalsDir = await KaraokeFiles.instance.folder('vocals');
    _mixesDir = await KaraokeFiles.instance.folder('mixes');

    _takes.clear();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        for (final item in jsonDecode(raw) as List) {
          final take = RecordingTake.fromJson((item as Map).cast<String, dynamic>());
          // A take without its vocals cannot be mixed again.
          if (!await File(vocalsPath(take)).exists()) continue;
          final renders = <MixRender>[
            for (final r in take.renders)
              if (await File(renderPath(r)).exists()) r,
          ];
          _takes.add(take.copyWith(renders: renders));
        }
      } catch (e) {
        debugPrint('Could not read saved recordings: $e');
      }
    }
    unawaited(KaraokeFiles.instance.clearOldPreviews());
  }

  Future<RecordingTake> addTake(Track track, RecordingResult result) async {
    final take = RecordingTake(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      title: '${track.title} (My cover)',
      track: track,
      vocalsFile: _fileName(result.vocalsPath),
      length: result.length,
      musicOffset: result.musicOffset,
      interrupted: result.interrupted,
      createdAt: DateTime.now(),
    );
    _takes.add(take);
    await _save();
    notifyListeners();
    return take;
  }

  Future<RecordingTake?> updateSettings(String id, MixSettings settings) =>
      _update(id, (t) => t.copyWith(settings: settings));

  Future<RecordingTake?> rename(String id, String title) {
    final clean = title.trim();
    if (clean.isEmpty) return Future.value(byId(id));
    return _update(id, (t) => t.copyWith(title: clean));
  }

  /// Saves [render] for the take, keeping only the newest one per settings
  /// and format, and deletes the file it replaces.
  Future<RecordingTake?> addRender(String id, MixRender render) async {
    final take = byId(id);
    if (take == null) return null;
    final keep = <MixRender>[];
    for (final r in take.renders) {
      if (r.settingsHash == render.settingsHash &&
          r.format == render.format &&
          r.isVideo == render.isVideo &&
          r.file != render.file) {
        await KaraokeFiles.instance.deleteIfExists(renderPath(r));
      } else {
        keep.add(r);
      }
    }
    return _update(id, (t) => t.copyWith(renders: [...keep, render]));
  }

  /// Deletes the take, its raw vocals and every mix made from it.
  Future<void> delete(String id) async {
    final take = byId(id);
    if (take == null) return;
    _takes.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
    await KaraokeFiles.instance.deleteIfExists(vocalsPath(take));
    for (final r in take.renders) {
      await KaraokeFiles.instance.deleteIfExists(renderPath(r));
    }
  }

  Future<RecordingTake?> _update(
      String id, RecordingTake Function(RecordingTake) change) async {
    final i = _takes.indexWhere((t) => t.id == id);
    if (i == -1) return null;
    _takes[i] = change(_takes[i]);
    await _save();
    notifyListeners();
    return _takes[i];
  }

  Future<void> _save() async {
    await _prefs?.setString(
        _key, jsonEncode([for (final t in _takes) t.toJson()]));
  }

  String _join(Directory dir, String file) =>
      '${dir.path}${Platform.pathSeparator}$file';

  String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;
}
