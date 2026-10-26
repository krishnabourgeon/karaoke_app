// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// const String kUnknownDuration = '--:--';

// enum DownloadResult { saved, cancelled, notEnoughPoints, failed }

// /// Stand-in for your backend while there is no API.
// /// Uploaded files are copied into the app's documents folder and listed
// /// next to the sample tracks. Points and downloads are saved on the device.
// ///
// /// When the API is ready, keep the method names and replace the bodies
// /// with network calls, so the screens do not change.
// class LibraryStore extends ChangeNotifier {
//   LibraryStore._();
//   static final LibraryStore instance = LibraryStore._();

//   static const int uploadReward = 20;
//   static const int startingPoints = 85;
//   static const String _kUploads = 'swaram_uploads';
//   static const String _kPoints = 'swaram_points';
//   static const String _kDownloaded = 'swaram_downloaded';

//   SharedPreferences? _prefs;
//   late Directory _tracksDir;

//   final List<Track> _uploaded = [];
//   final Set<String> _downloaded = {};
//   int _points = startingPoints;
//   String uploaderName = '@arjun_n';

//   int get points => _points;

//   /// Newest uploads first, then the sample tracks.
//   List<Track> get tracks => [..._uploaded.reversed, ...kSampleTracks];

//   bool isDownloaded(String id) => _downloaded.contains(id);

//   /// Call once in main() before runApp.
//   Future<void> init() async {
//     _prefs = await SharedPreferences.getInstance();

//     final docs = await getApplicationDocumentsDirectory();
//     _tracksDir = Directory('${docs.path}${Platform.pathSeparator}tracks');
//     if (!await _tracksDir.exists()) {
//       await _tracksDir.create(recursive: true);
//     }

//     _points = _prefs!.getInt(_kPoints) ?? startingPoints;
//     _downloaded
//       ..clear()
//       ..addAll(_prefs!.getStringList(_kDownloaded) ?? const <String>[]);

//     final raw = _prefs!.getString(_kUploads);
//     if (raw != null) {
//       try {
//         for (final item in jsonDecode(raw) as List) {
//           final m = item as Map<String, dynamic>;
//           // Only the file name is saved, because the documents folder path
//           // can change between app launches on iOS.
//           final file =
//               File('${_tracksDir.path}${Platform.pathSeparator}${m['file']}');
//           if (!await file.exists()) continue;
//           _uploaded.add(Track(
//             id: m['id'] as String,
//             title: m['title'] as String,
//             language: m['language'] as String,
//             duration: m['duration'] as String,
//             uploader: m['uploader'] as String,
//             localPath: file.path,
//             isVideo: m['isVideo'] as bool? ?? false,
//             genre: m['genre'] as String,
//             vibe: m['vibe'] as String,
//           ));
//         }
//       } catch (_) {
//         // Corrupt saved data: start with an empty uploads list.
//       }
//     }
//   }

//   /// Copies [sourcePath] into the app folder and adds it to the library.
//   Future<Track> addUpload({
//     required String sourcePath,
//     required String title,
//     required String language,
//     required bool isVideo,
//     required String genre,
//     required String vibe
//   }) async {
//     final id = 'u${DateTime.now().millisecondsSinceEpoch}';
//     final dest = File(
//         '${_tracksDir.path}${Platform.pathSeparator}$id${_extension(sourcePath, isVideo: isVideo)}');
//     await File(sourcePath).copy(dest.path);

//     final track = Track(
//       id: id,
//       title: title.trim(),
//       language: language,
//       duration: kUnknownDuration, // filled in the first time it plays
//       uploader: uploaderName,
//       localPath: dest.path,
//       isVideo: isVideo,
//       vibe: vibe,
//       genre: genre,
//     );

//     _uploaded.add(track);
//     _points += uploadReward;
//     await _save();
//     notifyListeners();
//     return track;
//   }

//   /// Called by the player once the real length of an uploaded file is known.
//   Future<void> updateDuration(String id, Duration duration) async {
//     final i = _uploaded.indexWhere((t) => t.id == id);
//     if (i == -1) return;
//     final text =
//         '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
//     if (_uploaded[i].duration == text) return;
//     _uploaded[i] = _uploaded[i].withDuration(text);
//     await _save();
//     notifyListeners();
//   }

//   /// Saves the track to a place the user picks, then charges the points.
//   /// Saving the same track again is free.
//   Future<DownloadResult> download(Track track) async {
//     final owned = _downloaded.contains(track.id);
//     if (!owned && _points < track.points) return DownloadResult.notEnoughPoints;

//     try {
//       final bytes = track.localPath != null
//           ? await File(track.localPath!).readAsBytes()
//           : await _fetch(track.audioUrl);
//       final ext = track.localPath != null
//     ? _extension(track.localPath!, isVideo: track.isVideo)
//     : (track.isVideo ? '.mp4' : '.mp3');

//       final saved = await FilePicker.saveFile(
//         dialogTitle: 'Save karaoke',
//         fileName: '${_safeName(track.title)}$ext',
//         bytes: bytes,
//       );
//       if (saved == null) return DownloadResult.cancelled;

//       if (!owned) {
//         _points -= track.points;
//         _downloaded.add(track.id);
//         await _save();
//         notifyListeners();
//       }
//       return DownloadResult.saved;
//     } catch (_) {
//       return DownloadResult.failed;
//     }
//   }

//   Future<Uint8List> _fetch(String url) async {
//     final client = HttpClient();
//     try {
//       final request = await client.getUrl(Uri.parse(url));
//       final response = await request.close();
//       if (response.statusCode != 200) {
//         throw HttpException('HTTP ${response.statusCode}');
//       }
//       final builder = BytesBuilder(copy: false);
//       await for (final chunk in response) {
//         builder.add(chunk);
//       }
//       return builder.takeBytes();
//     } finally {
//       client.close();
//     }
//   }

//   String _extension(String path, {bool isVideo = false}) {
//     final dot = path.lastIndexOf('.');
//     final slash = path.lastIndexOf(Platform.pathSeparator);
//   final fallback = isVideo ? '.mp4' : '.mp3';
//   return (dot == -1 || dot < slash) ? fallback : path.substring(dot).toLowerCase();
//   }

//   String _safeName(String title) =>
//       title.replaceAll(RegExp(r'[^\w\- ]'), '').trim().replaceAll(' ', '_');

//   Future<void> _save() async {
//     final p = _prefs;
//     if (p == null) return;
//     await p.setInt(_kPoints, _points);
//     await p.setStringList(_kDownloaded, _downloaded.toList());
//     await p.setString(
//       _kUploads,
//       jsonEncode(_uploaded
//           .map((t) => {
//                 'id': t.id,
//                 'title': t.title,
//                 'language': t.language,
//                 'duration': t.duration,
//                 'uploader': t.uploader,
//                 'isVideo': t.isVideo,
//                 'file': t.localPath!.split(Platform.pathSeparator).last,

//               })
//           .toList()),
//     );
//   }
// }




import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kUnknownDuration = '--:--';

enum DownloadResult { saved, cancelled, notEnoughPoints, failed }

/// Stand-in for your backend while there is no API.
/// Uploaded files are copied into the app's documents folder and listed
/// next to the sample tracks. Points and downloads are saved on the device.
///
/// When the API is ready, keep the method names and replace the bodies
/// with network calls, so the screens do not change.
class LibraryStore extends ChangeNotifier {
  LibraryStore._();
  static final LibraryStore instance = LibraryStore._();

  static const int uploadReward = 20;
  static const int startingPoints = 85;
  static const String _kUploads = 'swaram_uploads';
  static const String _kPoints = 'swaram_points';
  static const String _kDownloaded = 'swaram_downloaded';

  SharedPreferences? _prefs;
  late Directory _tracksDir;

  final List<Track> _uploaded = [];
  final Set<String> _downloaded = {};
  int _points = startingPoints;
  String uploaderName = '@arjun_n';

  int get points => _points;

  /// Newest uploads first, then the sample tracks.
  List<Track> get tracks => [..._uploaded.reversed, ...kSampleTracks];

  bool isDownloaded(String id) => _downloaded.contains(id);

  /// Call once in main() before runApp.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final docs = await getApplicationDocumentsDirectory();
    _tracksDir = Directory('${docs.path}${Platform.pathSeparator}tracks');
    if (!await _tracksDir.exists()) {
      await _tracksDir.create(recursive: true);
    }

    _points = _prefs!.getInt(_kPoints) ?? startingPoints;
    _downloaded
      ..clear()
      ..addAll(_prefs!.getStringList(_kDownloaded) ?? const <String>[]);

    final raw = _prefs!.getString(_kUploads);
    if (raw != null) {
      try {
        for (final item in jsonDecode(raw) as List) {
          final m = item as Map<String, dynamic>;
          // Only the file name is saved, because the documents folder path
          // can change between app launches on iOS.
          final file =
              File('${_tracksDir.path}${Platform.pathSeparator}${m['file']}');
          if (!await file.exists()) continue;
          _uploaded.add(Track(
            id: m['id'] as String,
            title: m['title'] as String,
            language: m['language'] as String,
            duration: m['duration'] as String,
            uploader: m['uploader'] as String,
            localPath: file.path,
            isVideo: m['isVideo'] as bool? ?? false,
            // Older saved uploads have no genre or vibe, so default to ''.
            genre: (m['genre'] as String?) ?? '',
            vibe: (m['vibe'] as String?) ?? '',
          ));
        }
      } catch (_) {
        // Corrupt saved data: start with an empty uploads list.
      }
    }
  }

  /// Copies [sourcePath] into the app folder and adds it to the library.
  /// Pass '' for [genre] or [vibe] when the user did not pick one.
  Future<Track> addUpload({
    required String sourcePath,
    required String title,
    required String language,
    required bool isVideo,
    required String genre,
    required String vibe,
  }) async {
    final id = 'u${DateTime.now().millisecondsSinceEpoch}';
    final dest = File(
        '${_tracksDir.path}${Platform.pathSeparator}$id${_extension(sourcePath, isVideo: isVideo)}');
    await File(sourcePath).copy(dest.path);

    final track = Track(
      id: id,
      title: title.trim(),
      language: language,
      duration: kUnknownDuration, // filled in the first time it plays
      uploader: uploaderName,
      localPath: dest.path,
      isVideo: isVideo,
      vibe: vibe,
      genre: genre,
    );

    _uploaded.add(track);
    _points += uploadReward;
    await _save();
    notifyListeners();
    return track;
  }

  /// Called by the player once the real length of an uploaded file is known.
  Future<void> updateDuration(String id, Duration duration) async {
    final i = _uploaded.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final text =
        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    if (_uploaded[i].duration == text) return;
    _uploaded[i] = _uploaded[i].withDuration(text);
    await _save();
    notifyListeners();
  }

  /// Saves the track to a place the user picks, then charges the points.
  /// Saving the same track again is free.
  Future<DownloadResult> download(Track track) async {
    final owned = _downloaded.contains(track.id);
    if (!owned && _points < track.points) return DownloadResult.notEnoughPoints;

    try {
      final bytes = track.localPath != null
          ? await File(track.localPath!).readAsBytes()
          : await _fetch(track.audioUrl);
      final ext = track.localPath != null
          ? _extension(track.localPath!, isVideo: track.isVideo)
          : (track.isVideo ? '.mp4' : '.mp3');

      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save karaoke',
        fileName: '${_safeName(track.title)}$ext',
        bytes: bytes,
      );
      if (saved == null) return DownloadResult.cancelled;

      if (!owned) {
        _points -= track.points;
        _downloaded.add(track.id);
        await _save();
        notifyListeners();
      }
      return DownloadResult.saved;
    } catch (_) {
      return DownloadResult.failed;
    }
  }

  Future<Uint8List> _fetch(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  String _extension(String path, {bool isVideo = false}) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf(Platform.pathSeparator);
    final fallback = isVideo ? '.mp4' : '.mp3';
    return (dot == -1 || dot < slash)
        ? fallback
        : path.substring(dot).toLowerCase();
  }

  String _safeName(String title) =>
      title.replaceAll(RegExp(r'[^\w\- ]'), '').trim().replaceAll(' ', '_');

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt(_kPoints, _points);
    await p.setStringList(_kDownloaded, _downloaded.toList());
    await p.setString(
      _kUploads,
      jsonEncode(_uploaded
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'language': t.language,
                'duration': t.duration,
                'uploader': t.uploader,
                'isVideo': t.isVideo,
                'genre': t.genre,
                'vibe': t.vibe,
                'file': t.localPath!.split(Platform.pathSeparator).last,
              })
          .toList()),
    );
  }
}