// import 'dart:async';
// import 'dart:io';
// import 'dart:math' as math;

// import 'package:flutter/foundation.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:karaoke_app/model/mix_settings.dart';
// import 'package:karaoke_app/model/recording_take.dart';
// import 'package:karaoke_app/service/audio_mixier.dart';
// import 'package:karaoke_app/service/karaoke_files.dart';
// import 'package:karaoke_app/service/mix_timing.dart' as timing;
// import 'package:karaoke_app/service/recordings_store.dart';
// import 'package:karaoke_app/service/waveform_service.dart';
// import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';

// enum StudioStatus { loading, ready, error }

// /// What the preview plays: the processed mix, the same mix without effects,
// /// or the raw microphone file exactly as recorded.
// enum PreviewMode { after, before, raw }

// /// State of the Mix Studio for one take.
// ///
// /// just_audio_background allows only one player, so previews are short clips
// /// rendered by FFmpeg with the exact export settings and played through
// /// [SwaramPlayer]. Every clip is named by its settings hash, so an old clip
// /// can never be played for newer settings.
// class MixStudioController extends ChangeNotifier {
//   MixStudioController(RecordingTake take)
//       : _take = take,
//         _settings = take.settings;

//   static const int previewLengthMs = 20000;
//   static const int _undoLimit = 30;

//   final SwaramPlayer _player = SwaramPlayer.instance;
//   final RecordingsStore _store = RecordingsStore.instance;

//   RecordingTake _take;
//   MixSettings _settings;
//   final List<MixSettings> _undo = [];

//   StudioStatus status = StudioStatus.loading;
//   String? error;
//   double? loadProgress;

//   BackingTrack? _backing;
//   Duration? _backingLength;
//   Waveform? musicWave;
//   Waveform? vocalWave;

//   PreviewMode mode = PreviewMode.after;
//   bool rendering = false;
//   double renderProgress = 0;
//   bool exporting = false;
//   double exportProgress = 0;
//   bool playing = false;

//   /// Song time (ms) under the playhead.
//   int playheadMs = 0;

//   String? _previewPath;
//   int _previewOffsetMs = 0; // song time = player position + this
//   int _token = 0;
//   int? _sessionId;
//   bool _disposed = false;
//   Timer? _previewDebounce;
//   Timer? _saveDebounce;
//   final List<StreamSubscription<dynamic>> _subs = [];

//   RecordingTake get take => _take;
//   MixSettings get settings => _settings;
//   bool get canUndo => _undo.isNotEmpty;
//   bool get hasVideo => _backing?.video != null;
//   String get vocalsPath => _store.vocalsPath(_take);

//   int get musicOffsetMs => _take.musicOffset.inMilliseconds;

//   /// Song length before trims, for the current timing offset.
//   int get fullSongMs => timing.fullSongMs(
//         vocalsLengthMs: _take.length.inMilliseconds,
//         musicOffsetMs: musicOffsetMs,
//         offsetMs: _settings.offsetMs,
//         backingLengthMs: _backingLength?.inMilliseconds,
//       );

//   Future<void> init() async {
//     status = StudioStatus.loading;
//     error = null;
//     _notify();
//     try {
//       if (!await File(vocalsPath).exists()) {
//         throw const KaraokeException('This recording is no longer on the device.');
//       }
//       // Cached backing files can be cleared by the OS; this re-downloads them.
//       _backing = await KaraokeFiles.instance.prepareBacking(
//         _take.track,
//         onProgress: (p) {
//           loadProgress = p;
//           _notify();
//         },
//       );
//       _backingLength = await AudioMixer.probeDuration(_backing!.audio.path);
//       status = StudioStatus.ready;
//       _listenToPlayer();
//       _notify();
//       unawaited(_loadWaveforms());
//     } on KaraokeException catch (e) {
//       status = StudioStatus.error;
//       error = e.message;
//       _notify();
//     } catch (e) {
//       debugPrint('Mix studio failed to open: $e');
//       status = StudioStatus.error;
//       error = 'Could not open the mix studio. Please try again.';
//       _notify();
//     }
//   }

//   // ---------- settings ----------

//   /// Call when a slider drag starts, so the whole drag is one undo step.
//   void beginEdit() {
//     _undo.add(_settings);
//     if (_undo.length > _undoLimit) _undo.removeAt(0);
//     _notify();
//   }

//   /// Live change (slider drag). Re-renders the preview once the user pauses.
//   void edit(MixSettings next) {
//     if (next == _settings) return;
//     _settings = next;
//     playheadMs = playheadMs.clamp(0, math.max(0, fullSongMs - 1));
//     _notify();
//     _scheduleSave();
//     if (playing || rendering) _schedulePreview();
//   }

//   /// A single change (button, chip): one undo step.
//   void apply(MixSettings next) {
//     if (next == _settings) return;
//     beginEdit();
//     edit(next);
//   }

//   void applyPreset(MixPreset preset) => apply(_settings.withPreset(preset));

//   void undo() {
//     if (_undo.isEmpty) return;
//     edit(_undo.removeLast());
//   }

//   void reset() => apply(MixSettings.defaults);

//   void setMode(PreviewMode next) {
//     if (mode == next) return;
//     mode = next;
//     _notify();
//     if (playing) unawaited(_playPreview(fromMs: playheadMs));
//   }

//   // ---------- preview ----------

//   Future<void> togglePlay() async {
//     if (playing) {
//       await _player.pause();
//       return;
//     }
//     await _playPreview(fromMs: playheadMs);
//   }

//   void seek(int songMs) {
//     playheadMs = songMs.clamp(0, math.max(0, fullSongMs - 1));
//     _notify();
//     if (playing) unawaited(_playPreview(fromMs: playheadMs));
//   }

//   Future<void> cancelRender() async {
//     _token++;
//     final id = _sessionId;
//     if (id != null) await AudioMixer.cancelSession(id);
//     rendering = false;
//     _notify();
//   }

//   Future<void> _playPreview({required int fromMs}) async {
//     final backing = _backing;
//     if (backing == null) return;
//     final token = ++_token;
//     final running = _sessionId;
//     if (running != null) unawaited(AudioMixer.cancelSession(running));

//     if (mode == PreviewMode.raw) {
//       // The microphone file as recorded, starting at the matching moment.
//       final lead = timing.vocalLeadMs(
//           musicOffsetMs: musicOffsetMs, offsetMs: _settings.offsetMs);
//       final vocalMs = math.max(0, fromMs + lead);
//       _previewPath = vocalsPath;
//       _previewOffsetMs = -lead;
//       await _player.playTrackAt(
//           _clipTrack(vocalsPath, 'Raw vocals'), Duration(milliseconds: vocalMs));
//       return;
//     }

//     final s = mode == PreviewMode.before ? _settings.dry : _settings;
//     final full = fullSongMs;
//     var start = math.min(math.max(fromMs, 0), math.max(0, full - 1000));
//     final end = math.min(start + previewLengthMs, full);
//     if (end <= start) start = 0;
//     final window = timing.planWindow(
//       startMs: start,
//       endMs: math.max(end, start + 1),
//       musicOffsetMs: musicOffsetMs,
//       offsetMs: s.offsetMs,
//     );
//     final path = await KaraokeFiles.instance.previewPath(
//         '${_take.id}_${s.hash}_${window.startMs}_${window.durationMs}');

//     if (!await File(path).exists()) {
//       rendering = true;
//       renderProgress = 0;
//       _notify();
//       // Render to a temporary name so a killed app never leaves a half
//       // file that looks like a finished preview.
//       final tmp = path.replaceFirst('.m4a', '_tmp.m4a');
//       int? mine;
//       try {
//         await AudioMixer.render(
//           backingPath: backing.audio.path,
//           vocalsPath: vocalsPath,
//           settings: s,
//           window: window,
//           outputPath: tmp,
//           validate: false,
//           onSession: (id) => _sessionId = mine = id,
//           onProgress: (p) {
//             if (token != _token) return;
//             renderProgress = p;
//             _notify();
//           },
//         );
//         await File(tmp).rename(path);
//       } on KaraokeException catch (e) {
//         if (token == _token) {
//           rendering = false;
//           if (e.message != AudioMixer.cancelledMessage) error = e.message;
//           _notify();
//         }
//         return;
//       } finally {
//         if (_sessionId == mine) _sessionId = null;
//       }
//     }
//     if (token != _token || _disposed) return; // newer settings won
//     rendering = false;
//     error = null;
//     _previewPath = path;
//     _previewOffsetMs = window.startMs;
//     _notify();
//     await _player.playFile(_clipTrack(path, _take.title));
//   }

//   void _schedulePreview() {
//     _previewDebounce?.cancel();
//     _previewDebounce = Timer(const Duration(milliseconds: 450),
//         () => unawaited(_playPreview(fromMs: playheadMs)));
//   }

//   void _listenToPlayer() {
//     _subs
//       ..add(_player.positionStream.listen((p) {
//         if (!_isOurs) return;
//         final song = p.inMilliseconds + _previewOffsetMs;
//         if ((song - playheadMs).abs() >= 50) {
//           playheadMs = song.clamp(0, math.max(0, fullSongMs - 1));
//           _notify();
//         }
//       }))
//       ..add(_player.stateStream.listen((s) {
//         final now = _isOurs &&
//             s.playing &&
//             s.processingState != ProcessingState.completed;
//         if (now != playing) {
//           playing = now;
//           _notify();
//         }
//       }));
//   }

//   bool get _isOurs =>
//       _previewPath != null && _player.currentTrack.value?.localPath == _previewPath;

//   Track _clipTrack(String path, String title) => Track(
//         id: 'studio_${fnv1a(path)}',
//         title: title,
//         language: _take.track.language,
//         duration: '',
//         uploader: _take.track.uploader,
//         localPath: path,
//         genre: _take.track.genre,
//         vibe: _take.track.vibe,
//       );

//   // ---------- export ----------

//   /// Renders the full song with the current settings, or returns the saved
//   /// render when these exact settings were already exported.
//   Future<MixOutput> export({
//     ExportFormat format = ExportFormat.m4a,
//     bool withVideo = false,
//   }) async {
//     final backing = _backing;
//     if (backing == null) throw const KaraokeException('The karaoke track is not ready yet.');
//     await cancelRender();
//     await _player.pause();

//     final video = withVideo ? backing.video : null;
//     final existing = _take.renderFor(_settings, format: format);
//     if (existing != null && existing.isVideo == (video != null)) {
//       final path = _store.renderPath(existing);
//       if (await File(path).exists()) return MixOutput(path, isVideo: existing.isVideo);
//     }

//     exporting = true;
//     exportProgress = 0;
//     _notify();
//     try {
//       MixOutput output;
//       try {
//         output = await _renderFull(backing, format, video?.path);
//       } on KaraokeException catch (e) {
//         if (video == null || e.message == AudioMixer.cancelledMessage) rethrow;
//         debugPrint('Video export failed, falling back to audio only.');
//         output = await _renderFull(backing, format, null);
//       }
//       final updated = await _store.addRender(
//         _take.id,
//         MixRender(
//           file: output.path.split(RegExp(r'[\\/]')).last,
//           format: output.isVideo ? ExportFormat.m4a : format,
//           isVideo: output.isVideo,
//           settingsHash: _settings.hash,
//           createdAt: DateTime.now(),
//         ),
//       );
//       if (updated != null) _take = updated;
//       return output;
//     } finally {
//       exporting = false;
//       _sessionId = null;
//       _notify();
//     }
//   }

//   Future<void> cancelExport() async {
//     final id = _sessionId;
//     if (id != null) await AudioMixer.cancelSession(id);
//   }

//   Future<MixOutput> _renderFull(
//       BackingTrack backing, ExportFormat format, String? videoPath) async {
//     // Copied video can only start on a keyframe, so a video export keeps the
//     // song start and applies only the end trim.
//     final window = timing.planExport(
//       vocalsLengthMs: _take.length.inMilliseconds,
//       musicOffsetMs: musicOffsetMs,
//       offsetMs: _settings.offsetMs,
//       trimStartMs: videoPath == null ? _settings.trimStartMs : 0,
//       trimEndMs: _settings.trimEndMs,
//       backingLengthMs: _backingLength?.inMilliseconds,
//     );
//     final out = await KaraokeFiles.instance
//         .newRenderPath(videoPath != null ? '.mp4' : format.extension);
//     return AudioMixer.render(
//       backingPath: backing.audio.path,
//       vocalsPath: vocalsPath,
//       settings: _settings,
//       window: window,
//       outputPath: out,
//       format: format,
//       videoPath: videoPath,
//       onSession: (id) => _sessionId = id,
//       onProgress: (p) {
//         exportProgress = p;
//         _notify();
//       },
//     );
//   }

//   // ---------- helpers ----------

//   Future<void> _loadWaveforms() async {
//     final backing = _backing;
//     if (backing == null) return;
//     final results = await Future.wait([
//       WaveformService.instance.load(backing.audio.path),
//       WaveformService.instance.load(vocalsPath),
//     ]);
//     musicWave = results[0];
//     vocalWave = results[1];
//     _notify();
//   }

//   void _scheduleSave() {
//     _saveDebounce?.cancel();
//     _saveDebounce = Timer(const Duration(milliseconds: 600), _saveNow);
//   }

//   void _saveNow() {
//     unawaited(_store.updateSettings(_take.id, _settings).then((t) {
//       if (t != null) _take = t;
//     }));
//   }

//   void _notify() {
//     if (!_disposed) notifyListeners();
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     _previewDebounce?.cancel();
//     if (_saveDebounce?.isActive ?? false) {
//       _saveDebounce!.cancel();
//       _saveNow();
//     }
//     for (final s in _subs) {
//       unawaited(s.cancel());
//     }
//     final id = _sessionId;
//     if (id != null) unawaited(AudioMixer.cancelSession(id));
//     if (_isOurs) unawaited(_player.pause());
//     super.dispose();
//   }
// }




import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:karaoke_app/model/mix_settings.dart';
import 'package:karaoke_app/model/recording_take.dart';
import 'package:karaoke_app/service/audio_mixier.dart';
import 'package:karaoke_app/service/karaoke_files.dart';
import 'package:karaoke_app/service/mix_timing.dart' as timing;
import 'package:karaoke_app/service/recordings_store.dart';
import 'package:karaoke_app/service/waveform_service.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';

enum StudioStatus { loading, ready, error }

/// What the preview plays: the processed mix, the same mix without effects,
/// or the raw microphone file exactly as recorded.
enum PreviewMode { after, before, raw }

/// State of the Mix Studio for one take.
///
/// just_audio_background allows only one player, so previews are short clips
/// rendered by FFmpeg with the exact export settings and played through
/// [SwaramPlayer]. Every clip is named by its settings hash, so an old clip
/// can never be played for newer settings.
class MixStudioController extends ChangeNotifier {
  MixStudioController(RecordingTake take)
      : _take = take,
        _settings = take.settings;

  static const int previewLengthMs = 20000;
  static const int _undoLimit = 30;

  final SwaramPlayer _player = SwaramPlayer.instance;
  final RecordingsStore _store = RecordingsStore.instance;

  RecordingTake _take;
  MixSettings _settings;
  final List<MixSettings> _undo = [];

  StudioStatus status = StudioStatus.loading;
  String? error;
  double? loadProgress;

  BackingTrack? _backing;
  Duration? _backingLength;
  Waveform? musicWave;
  Waveform? vocalWave;

  PreviewMode mode = PreviewMode.after;
  bool rendering = false;
  double renderProgress = 0;
  bool exporting = false;
  double exportProgress = 0;
  bool playing = false;

  /// Song time (ms) under the playhead.
  int playheadMs = 0;

  String? _previewPath;
  int _previewOffsetMs = 0; // song time = player position + this
  int _token = 0;
  int? _sessionId;
  bool _disposed = false;
  Timer? _previewDebounce;
  Timer? _saveDebounce;
  final List<StreamSubscription<dynamic>> _subs = [];

  RecordingTake get take => _take;
  MixSettings get settings => _settings;
  bool get canUndo => _undo.isNotEmpty;
  bool get hasVideo => _backing?.video != null;
  String get vocalsPath => _store.vocalsPath(_take);

  int get musicOffsetMs => _take.musicOffset.inMilliseconds;

  /// Song length before trims, for the current timing offset.
  int get fullSongMs => timing.fullSongMs(
        vocalsLengthMs: _take.length.inMilliseconds,
        musicOffsetMs: musicOffsetMs,
        offsetMs: _settings.offsetMs,
        backingLengthMs: _backingLength?.inMilliseconds,
      );

  Future<void> init() async {
    status = StudioStatus.loading;
    error = null;
    _notify();
    try {
      if (!await File(vocalsPath).exists()) {
        throw const KaraokeException('This recording is no longer on the device.');
      }
      // Cached backing files can be cleared by the OS; this re-downloads them.
      _backing = await KaraokeFiles.instance.prepareBacking(
        _take.track,
        onProgress: (p) {
          loadProgress = p;
          _notify();
        },
      );
      _backingLength = await AudioMixer.probeDuration(_backing!.audio.path);
      status = StudioStatus.ready;
      _listenToPlayer();
      _notify();
      unawaited(_loadWaveforms());
    } on KaraokeException catch (e) {
      status = StudioStatus.error;
      error = e.message;
      _notify();
    } catch (e) {
      debugPrint('Mix studio failed to open: $e');
      status = StudioStatus.error;
      error = 'Could not open the mix studio. Please try again.';
      _notify();
    }
  }

  // ---------- settings ----------

  /// Call when a slider drag starts, so the whole drag is one undo step.
  void beginEdit() {
    _undo.add(_settings);
    if (_undo.length > _undoLimit) _undo.removeAt(0);
    _notify();
  }

  /// Live change (slider drag). Re-renders the preview once the user pauses.
  void edit(MixSettings next) {
    if (next == _settings) return;
    _settings = next;
    playheadMs = playheadMs.clamp(0, math.max(0, fullSongMs - 1));
    _notify();
    _scheduleSave();
    if (playing || rendering) _schedulePreview();
  }

  /// A single change (button, chip): one undo step.
  void apply(MixSettings next) {
    if (next == _settings) return;
    beginEdit();
    edit(next);
  }

  void applyPreset(MixPreset preset) => apply(_settings.withPreset(preset));

  void undo() {
    if (_undo.isEmpty) return;
    edit(_undo.removeLast());
  }

  void reset() => apply(MixSettings.defaults);

  void setMode(PreviewMode next) {
    if (mode == next) return;
    mode = next;
    _notify();
    if (playing) unawaited(_playPreview(fromMs: playheadMs));
  }

  // ---------- preview ----------

  Future<void> togglePlay() async {
    if (playing) {
      await _player.pause();
      return;
    }
    await _playPreview(fromMs: playheadMs);
  }

  void seek(int songMs) {
    playheadMs = songMs.clamp(0, math.max(0, fullSongMs - 1));
    _notify();
    if (playing) unawaited(_playPreview(fromMs: playheadMs));
  }

  Future<void> cancelRender() async {
    _token++;
    final id = _sessionId;
    if (id != null) await AudioMixer.cancelSession(id);
    rendering = false;
    _notify();
  }

  Future<void> _playPreview({required int fromMs}) async {
    final backing = _backing;
    if (backing == null) return;
    final token = ++_token;
    final running = _sessionId;
    if (running != null) unawaited(AudioMixer.cancelSession(running));

    if (mode == PreviewMode.raw) {
      // The microphone file as recorded, starting at the matching moment.
      final lead = timing.vocalLeadMs(
          musicOffsetMs: musicOffsetMs, offsetMs: _settings.offsetMs);
      final vocalMs = math.max(0, fromMs + lead);
      _previewPath = vocalsPath;
      _previewOffsetMs = -lead;
      await _player.playTrackAt(
          _clipTrack(vocalsPath, 'Raw vocals'), Duration(milliseconds: vocalMs));
      return;
    }

    final s = mode == PreviewMode.before ? _settings.dry : _settings;
    final full = fullSongMs;
    var start = math.min(math.max(fromMs, 0), math.max(0, full - 1000));
    final end = math.min(start + previewLengthMs, full);
    if (end <= start) start = 0;
    final window = timing.planWindow(
      startMs: start,
      endMs: math.max(end, start + 1),
      musicOffsetMs: musicOffsetMs,
      offsetMs: s.offsetMs,
    );
    final path = await KaraokeFiles.instance.previewPath(
        '${_take.id}_${s.hash}_${window.startMs}_${window.durationMs}');

    if (!await File(path).exists()) {
      rendering = true;
      renderProgress = 0;
      _notify();
      // Render to a temporary name so a killed app never leaves a half
      // file that looks like a finished preview.
      final tmp = path.replaceFirst('.m4a', '_tmp.m4a');
      int? mine;
      try {
        await AudioMixer.render(
          backingPath: backing.audio.path,
          vocalsPath: vocalsPath,
          settings: s,
          window: window,
          outputPath: tmp,
          validate: false,
          onSession: (id) => _sessionId = mine = id,
          onProgress: (p) {
            if (token != _token) return;
            renderProgress = p;
            _notify();
          },
        );
        await File(tmp).rename(path);
      } on KaraokeException catch (e) {
        if (token == _token) {
          rendering = false;
          if (e.message != AudioMixer.cancelledMessage) error = e.message;
          _notify();
        }
        return;
      } finally {
        if (_sessionId == mine) _sessionId = null;
      }
    }
    if (token != _token || _disposed) return; // newer settings won
    rendering = false;
    error = null;
    _previewPath = path;
    _previewOffsetMs = window.startMs;
    _notify();
    await _player.playFile(_clipTrack(path, _take.title));
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 450),
        () => unawaited(_playPreview(fromMs: playheadMs)));
  }

  void _listenToPlayer() {
    _subs
      ..add(_player.positionStream.listen((p) {
        if (!_isOurs) return;
        final song = p.inMilliseconds + _previewOffsetMs;
        if ((song - playheadMs).abs() >= 50) {
          playheadMs = song.clamp(0, math.max(0, fullSongMs - 1));
          _notify();
        }
      }))
      ..add(_player.stateStream.listen((s) {
        final now = _isOurs &&
            s.playing &&
            s.processingState != ProcessingState.completed;
        if (now != playing) {
          playing = now;
          _notify();
        }
      }));
  }

  bool get _isOurs =>
      _previewPath != null && _player.currentTrack.value?.localPath == _previewPath;

  Track _clipTrack(String path, String title) => Track(
        id: 'studio_${fnv1a(path)}',
        title: title,
        language: _take.track.language,
        duration: '',
        uploader: _take.track.uploader,
        localPath: path,
        genre: _take.track.genre,
        vibe: _take.track.vibe,
      );

  // ---------- export ----------

  /// Renders the full song with the current settings, or returns the saved
  /// render when these exact settings were already exported.
  Future<MixOutput> export({
    ExportFormat format = ExportFormat.m4a,
    bool withVideo = false,
  }) async {
    final backing = _backing;
    if (backing == null) throw const KaraokeException('The karaoke track is not ready yet.');
    await cancelRender();
    await _player.pause();

    final video = withVideo ? backing.video : null;
    final existing = _take.renderFor(_settings, format: format);
    if (existing != null && existing.isVideo == (video != null)) {
      final path = _store.renderPath(existing);
      if (await File(path).exists()) return MixOutput(path, isVideo: existing.isVideo);
    }

    exporting = true;
    exportProgress = 0;
    _notify();
    try {
      MixOutput output;
      try {
        output = await _renderFull(backing, format, video?.path);
      } on KaraokeException catch (e) {
        if (video == null || e.message == AudioMixer.cancelledMessage) rethrow;
        debugPrint('Video export failed, falling back to audio only.');
        output = await _renderFull(backing, format, null);
      }
      final updated = await _store.addRender(
        _take.id,
        MixRender(
          file: output.path.split(RegExp(r'[\\/]')).last,
          format: output.isVideo ? ExportFormat.m4a : format,
          isVideo: output.isVideo,
          settingsHash: _settings.hash,
          createdAt: DateTime.now(),
        ),
      );
      if (updated != null) _take = updated;
      return output;
    } finally {
      exporting = false;
      _sessionId = null;
      _notify();
    }
  }

  Future<void> cancelExport() async {
    final id = _sessionId;
    if (id != null) await AudioMixer.cancelSession(id);
  }

  Future<MixOutput> _renderFull(
      BackingTrack backing, ExportFormat format, String? videoPath) async {
    // Copied video can only start on a keyframe, so a video export keeps the
    // song start and applies only the end trim.
    final window = timing.planExport(
      vocalsLengthMs: _take.length.inMilliseconds,
      musicOffsetMs: musicOffsetMs,
      offsetMs: _settings.offsetMs,
      trimStartMs: videoPath == null ? _settings.trimStartMs : 0,
      trimEndMs: _settings.trimEndMs,
      backingLengthMs: _backingLength?.inMilliseconds,
    );
    final out = await KaraokeFiles.instance
        .newRenderPath(videoPath != null ? '.mp4' : format.extension);
    return AudioMixer.render(
      backingPath: backing.audio.path,
      vocalsPath: vocalsPath,
      settings: _settings,
      window: window,
      outputPath: out,
      format: format,
      videoPath: videoPath,
      onSession: (id) => _sessionId = id,
      onProgress: (p) {
        exportProgress = p;
        _notify();
      },
    );
  }

  // ---------- helpers ----------

  Future<void> _loadWaveforms() async {
    final backing = _backing;
    if (backing == null) return;
    final results = await Future.wait([
      WaveformService.instance.load(backing.audio.path),
      WaveformService.instance.load(vocalsPath),
    ]);
    musicWave = results[0];
    vocalWave = results[1];
    _notify();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _saveNow);
  }

  void _saveNow() {
    unawaited(_store.updateSettings(_take.id, _settings).then((t) {
      if (t != null) _take = t;
    }));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _previewDebounce?.cancel();
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce!.cancel();
      _saveNow();
    }
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    final id = _sessionId;
    if (id != null) unawaited(AudioMixer.cancelSession(id));
    if (_isOurs) unawaited(_player.pause());
    super.dispose();
  }
}
