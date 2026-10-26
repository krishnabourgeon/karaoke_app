// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flutter/foundation.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';
// import 'package:karaoke_app/view/library_store.dart';

// /// One player for the whole app, so starting a song stops the previous one.
// class SwaramPlayer {
//   SwaramPlayer._() {
//     _player.processingStateStream.listen((state) {
//       if (state == ProcessingState.completed) _onCompleted();
//     });

//     // Uploaded files start with an unknown length; save it once known.
//     _player.durationStream.listen((d) {
//       final t = currentTrack.value;
//       if (d != null && t != null && t.localPath != null) {
//         LibraryStore.instance.updateDuration(t.id, d);
//       }
//     });
//   }

//   static final SwaramPlayer instance = SwaramPlayer._();

//   final AudioPlayer _player = AudioPlayer();
//   final math.Random _random = math.Random();

//   List<Track> _queue = const [];
//   int _index = -1;

//   final ValueNotifier<Track?> currentTrack = ValueNotifier<Track?>(null);
//   final ValueNotifier<bool> shuffle = ValueNotifier<bool>(false);
//   final ValueNotifier<bool> repeatOne = ValueNotifier<bool>(false);
//   final ValueNotifier<String?> error = ValueNotifier<String?>(null);

//   Stream<PlayerState> get stateStream => _player.playerStateStream;
//   Stream<Duration> get positionStream => _player.positionStream;
//   Stream<Duration?> get durationStream => _player.durationStream;

//   /// Start playing [queue] at [index].
//   Future<void> playQueue(List<Track> queue, int index) async {
//     _queue = queue;
//     await _load(index);
//   }

//   /// Replace the queue without interrupting the current song.
//   void updateQueue(List<Track> queue) {
//     _queue = queue;
//     _index = queue.indexWhere((t) => t.id == currentTrack.value?.id);
//   }

//   Future<void> _load(int index) async {
//     if (index < 0 || index >= _queue.length) return;
//     _index = index;
//     final track = _queue[index];
//     currentTrack.value = track;
//     error.value = null;
//     try {
//       await _player.setAudioSource(
//         AudioSource.uri(
//           track.localPath != null
//               ? Uri.file(track.localPath!)
//               : Uri.parse(track.audioUrl),
//           tag: MediaItem(
//             id: track.id,
//             title: track.title,
//             artist: track.uploader,
//             album: track.language,
//           ),
//         ),
//       );
//       // Do not await play(): it completes only when playback pauses or ends.
//       unawaited(_player.play());
//     } catch (_) {
//       error.value = 'Could not play this track. Check your connection.';
//     }
//   }

//   Future<void> togglePlay() async {
//     if (_index < 0) return;
//     final completed = _player.processingState == ProcessingState.completed;
//     if (_player.playing && !completed) {
//       await _player.pause();
//       return;
//     }
//     if (completed) await _player.seek(Duration.zero);
//     unawaited(_player.play());
//   }

//   Future<void> next() async {
//     if (_queue.isEmpty) return;
//     if (shuffle.value && _queue.length > 1) {
//       int n;
//       do {
//         n = _random.nextInt(_queue.length);
//       } while (n == _index);
//       await _load(n);
//       return;
//     }
//     await _load(_index < _queue.length - 1 ? _index + 1 : 0);
//   }

//   Future<void> previous() async {
//     if (_queue.isEmpty) return;
//     if (_player.position > const Duration(seconds: 3) || _index <= 0) {
//       await _player.seek(Duration.zero);
//     } else {
//       await _load(_index - 1);
//     }
//   }

//   Future<void> seek(Duration position) => _player.seek(position);

//   void toggleShuffle() => shuffle.value = !shuffle.value;

//   void toggleRepeat() {
//     repeatOne.value = !repeatOne.value;
//     _player.setLoopMode(repeatOne.value ? LoopMode.one : LoopMode.off);
//   }

//   void _onCompleted() {
//     if (shuffle.value) {
//       unawaited(next());
//     } else if (_index < _queue.length - 1) {
//       unawaited(_load(_index + 1));
//     }
//   }
// }

// /// Favourite (heart) state. In memory for now.
// class FavoritesStore {
//   FavoritesStore._();
//   static final FavoritesStore instance = FavoritesStore._();

//   final ValueNotifier<Set<String>> ids = ValueNotifier<Set<String>>(<String>{});

//   bool isFavorite(String id) => ids.value.contains(id);

//   void toggle(String id) {
//     final next = {...ids.value};
//     if (!next.remove(id)) next.add(id);
//     ids.value = next;
//     // TODO: save to your API or shared_preferences so favourites survive restarts.
//   }
// }







import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:karaoke_app/view/library_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'track.dart';

/// One player for the whole app, so starting a song stops the previous one.
class SwaramPlayer {
  SwaramPlayer._() {
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onCompleted();
    });

    // Uploaded files start with an unknown length; save it once known.
    _player.durationStream.listen((d) {
      final t = currentTrack.value;
      if (d != null && t != null && t.localPath != null) {
        LibraryStore.instance.updateDuration(t.id, d);
      }
    });
  }

  static final SwaramPlayer instance = SwaramPlayer._();

  final AudioPlayer _player = AudioPlayer();
  final math.Random _random = math.Random();

  List<Track> _queue = const [];
  int _index = -1;
  bool _karaokeMode = false;

  final ValueNotifier<Track?> currentTrack = ValueNotifier<Track?>(null);
  final ValueNotifier<bool> shuffle = ValueNotifier<bool>(false);
  final ValueNotifier<bool> repeatOne = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  Stream<PlayerState> get stateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Start playing [queue] at [index].
  Future<void> playQueue(List<Track> queue, int index) async {
    _karaokeMode = false;
  _queue = queue;
  await _load(index);
}


Duration get position => _player.position;
bool get playing => _player.playing;
List<Track> get queue => _queue;

Future<void> playTrackAt(Track track, Duration position) async {
  _karaokeMode = false;
  var i = _queue.indexWhere((t) => t.id == track.id);
  if (i == -1) { _queue = [track]; i = 0; }
  await _load(i, startAt: position);
}

  /// Replace the queue without interrupting the current song.
  void updateQueue(List<Track> queue) {
    _queue = queue;
    _index = queue.indexWhere((t) => t.id == currentTrack.value?.id);
  }

  /// Loads a local backing track paused at 0:00. The recorder calls [resume]
  /// once the microphone is running.
  Future<void> loadKaraoke(Track track, String filePath) async {
    _karaokeMode = true;
    _queue = [track.withLocalPath(filePath)];
    await _player.stop();
    await _load(0, autoplay: false);
  }

  /// Plays a file made on this device (vocals preview, finished mix).
  Future<void> playFile(Track track) async {
    _karaokeMode = true;
    _queue = [track];
    await _load(0);
  }

  void resume() => unawaited(_player.play());

  Future<void> _load(int index, {Duration? startAt, bool autoplay = true}) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    final track = _queue[index];
    currentTrack.value = track;
    error.value = null;
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          track.localPath != null
              ? Uri.file(track.localPath!)
              : Uri.parse(track.audioUrl),
          tag: MediaItem(
            id: track.id,
            title: track.title,
            artist: track.uploader,
            album: track.language,
          ),
        ),
        initialPosition: startAt,
      );
      // Do not await play(): it completes only when playback pauses or ends.
      if (autoplay) unawaited(_player.play());
    } catch (_) {
      error.value = 'Could not play this track. Check your connection.';
    }
  }

  Future<void> togglePlay() async {
    if (_index < 0) return;
    final completed = _player.processingState == ProcessingState.completed;
    if (_player.playing && !completed) {
      await _player.pause();
      return;
    }
    if (completed) await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (shuffle.value && _queue.length > 1) {
      int n;
      do {
        n = _random.nextInt(_queue.length);
      } while (n == _index);
      await _load(n);
      return;
    }
    await _load(_index < _queue.length - 1 ? _index + 1 : 0);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_player.position > const Duration(seconds: 3) || _index <= 0) {
      await _player.seek(Duration.zero);
    } else {
      await _load(_index - 1);
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> pause() => _player.pause();

  void toggleShuffle() => shuffle.value = !shuffle.value;

  void toggleRepeat() {
    repeatOne.value = !repeatOne.value;
    _player.setLoopMode(repeatOne.value ? LoopMode.one : LoopMode.off);
  }

  void _onCompleted() {
    if (_karaokeMode) return;
    if (shuffle.value) {
      unawaited(next());
    } else if (_index < _queue.length - 1) {
      unawaited(_load(_index + 1));
    }
  }
}

/// Favourite (heart) state, saved on the device.
/// Insertion order is kept, so the Library screen can show newest first.
class FavoritesStore {
  FavoritesStore._();
  static final FavoritesStore instance = FavoritesStore._();

  static const String _key = 'swaram_favorites';

  SharedPreferences? _prefs;
  final ValueNotifier<Set<String>> ids = ValueNotifier<Set<String>>(<String>{});

  /// Call once in main() before runApp.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    ids.value = (_prefs!.getStringList(_key) ?? const <String>[]).toSet();
  }

  bool isFavorite(String id) => ids.value.contains(id);

  void toggle(String id) {
    final next = {...ids.value};
    if (!next.remove(id)) next.add(id);
    ids.value = next;
    // TODO: also send this to your API when it exists.
    _prefs?.setStringList(_key, next.toList());
  }
}