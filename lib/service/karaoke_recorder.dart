import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:karaoke_app/service/karaoke_files.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';

enum MicPermission { granted, denied, permanentlyDenied }

class RecordingResult {
  final String vocalsPath;
  final String backingPath;
  final String? videoPath;
  final Duration length;

  /// How long the mic ran before the music started.
  final Duration musicOffset;
  final bool interrupted;

  const RecordingResult({
    required this.vocalsPath,
    required this.backingPath,
    required this.videoPath,
    required this.length,
    required this.musicOffset,
    required this.interrupted,
  });
}

class KaraokeRecorder {
  final AudioRecorder _mic = AudioRecorder();
  final SwaramPlayer _player = SwaramPlayer.instance;

  /// Microphone level 0..1 for the meter.
  final ValueNotifier<double> level = ValueNotifier<double>(0);

  /// The take ended by itself (song finished, call, headphones unplugged).
  void Function(RecordingResult take)? onAutoStop;
  void Function(String message)? onError;

  final List<StreamSubscription<dynamic>> _subs = [];
  BackingTrack? _backing;
  DateTime? _micStartedAt;
  Duration _musicOffset = Duration.zero;
  bool _stopping = false;
  bool _interrupted = false;

  bool get isRecording => _micStartedAt != null;

  static const RecordConfig _micConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    sampleRate: 44100,
    numChannels: 1,
    bitRate: 128000,
    // We handle interruptions ourselves so music and mic always stop together.
    audioInterruption: AudioInterruptionMode.none,
    // Keep Bluetooth earphones in music mode: the song plays in the earphones
    // and the phone's own mic records the voice.
    androidConfig: AndroidRecordConfig(manageBluetooth: false),
    iosConfig: IosRecordConfig(categoryOptions: [
      IosAudioCategoryOption.defaultToSpeaker,
      IosAudioCategoryOption.allowBluetoothA2DP,
    ]),
  );

  static final AudioSessionConfiguration _recordingSession =
      AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker |
        AVAudioSessionCategoryOptions.allowBluetoothA2dp,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    androidAudioAttributes: const AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  );

  Future<MicPermission> requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return MicPermission.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MicPermission.permanentlyDenied;
    }
    return MicPermission.denied;
  }

  /// Loads the backing track (paused at 0:00). Returns its length.
  Future<Duration?> prepare(Track track, BackingTrack backing) async {
    _backing = backing;
    await _player.loadKaraoke(track, backing.audio.path);
    final error = _player.error.value;
    if (error != null) throw KaraokeException(error);
    return _player.duration;
  }

  Future<void> start() async {
    final backing = _backing;
    if (backing == null) {
      throw const KaraokeException('The karaoke track is not ready yet.');
    }
    if (isRecording) return;
    _interrupted = false;
    _musicOffset = Duration.zero;

    final session = await AudioSession.instance;
    await session.configure(_recordingSession);
    if (!await session.setActive(true)) {
      throw const KaraokeException('Another app is using audio. Close it and try again.');
    }

    await _player.seek(Duration.zero);
    final path = await KaraokeFiles.instance.newVocalsPath();
    try {
      await _mic.start(_micConfig, path: path);
    } catch (e) {
      debugPrint('Microphone start failed: $e');
      await _restoreSession();
      throw const KaraokeException(
          'Could not start the microphone. Another app may be using it.');
    }

    // Mic first, then music: the vocals file starts with a short silence
    // that the mixer cuts off using _musicOffset.
    final micStartedAt = DateTime.now();
    _micStartedAt = micStartedAt;
    await WakelockPlus.enable();
    _listen(session);
    _player.resume();

    try {
      final position = await _player.positionStream
          .firstWhere((p) => p >= const Duration(milliseconds: 250))
          .timeout(const Duration(seconds: 10));
      final musicStartedAt = DateTime.now().subtract(position);
      final offset = musicStartedAt.difference(micStartedAt);
      _musicOffset = offset.isNegative ? Duration.zero : offset;
    } on TimeoutException {
      await cancel();
      throw const KaraokeException('The karaoke track did not start. Please try again.');
    }
  }

  /// Stops mic and music and returns the take.
  Future<RecordingResult?> stop() async {
    final startedAt = _micStartedAt;
    final backing = _backing;
    if (startedAt == null || backing == null || _stopping) return null;
    _stopping = true;
    try {
      await _cancelSubs();
      final length = DateTime.now().difference(startedAt);
      final path = await _mic.stop();
      await _player.pause();

      final file = path == null ? null : File(path);
      if (file == null || !await file.exists() || await file.length() == 0) {
        throw const KaraokeException(
            'Nothing was recorded. Check the microphone and try again.');
      }
      return RecordingResult(
        vocalsPath: file.path,
        backingPath: backing.audio.path,
        videoPath: backing.video?.path,
        length: length,
        musicOffset: _musicOffset,
        interrupted: _interrupted,
      );
    } finally {
      _micStartedAt = null;
      _stopping = false;
      level.value = 0;
      await WakelockPlus.disable();
      await _restoreSession();
    }
  }

  /// Throws the take away (re-record, leaving the screen).
  Future<void> cancel() async {
    if (!isRecording) return;
    await _cancelSubs();
    await _mic.cancel();
    await _player.pause();
    _micStartedAt = null;
    level.value = 0;
    await WakelockPlus.disable();
    await _restoreSession();
  }

  Future<void> dispose() async {
    await cancel();
    await _mic.dispose();
    level.dispose();
  }

  void _listen(AudioSession session) {
    _subs
      ..add(session.interruptionEventStream.listen((event) {
        debugPrint('Audio interruption: begin=${event.begin} type=${event.type}');
        // Ducking (a notification sound) is fine; a call or another app is not.
        if (event.begin && event.type != AudioInterruptionType.duck) {
          _autoStop(interrupted: true);
        }
      }))
      ..add(session.becomingNoisyEventStream.listen((_) {
        debugPrint('Audio interruption: headphones unplugged');
        _autoStop(interrupted: true);
      }))
      ..add(_player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) _autoStop();
      }))
      ..add(_mic.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((a) {
        level.value = ((a.current + 45) / 45).clamp(0.0, 1.0); // dBFS → 0..1
      }));
  }

  Future<void> _autoStop({bool interrupted = false}) async {
    _interrupted = interrupted;
    try {
      final take = await stop();
      if (take != null) onAutoStop?.call(take);
    } on KaraokeException catch (e) {
      onError?.call(e.message);
    }
  }

  Future<void> _cancelSubs() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  Future<void> _restoreSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }
}