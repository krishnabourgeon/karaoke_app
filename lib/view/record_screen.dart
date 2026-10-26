import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:karaoke_app/service/audio_mixier.dart';
import 'package:karaoke_app/service/karaoke_files.dart';
import 'package:karaoke_app/service/karaoke_recorder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/mix_result_screen.dart';

enum _RecState { idle, countdown, recording, recorded }

class RecordScreen extends StatefulWidget {
  final Track track; // API track, uploaded song or uploaded video
  final List<String> lyrics;
  final VoidCallback? onChangeSong;

  const RecordScreen({
    super.key,
    required this.track,
    this.lyrics = const [
      '♪  Intro  ♪',
      'Your first line appears here',
      'Lyrics scroll while you sing',
      'Follow the highlighted line',
      'Keep going, you are doing great',
      'The last line of the song',
      '♪  Outro  ♪',
    ],
    this.onChangeSong,
  });

  static Route<void> route(Track track) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => RecordScreen(track: track),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  _RecState _state = _RecState.idle;
  bool _countIn = true;
  int _count = 3;
  Duration _elapsed = Duration.zero;
  int _line = 0;
  bool _previewPlaying = false;

  final KaraokeRecorder _recorder = KaraokeRecorder();
  final SwaramPlayer _player = SwaramPlayer.instance;
  late Duration _songLength = _parseLength(widget.track.duration);

  BackingTrack? _backing;
  VideoPlayerController? _video; // muted guide for video tracks
  bool _preparing = true;
  double? _downloadProgress;
  String? _prepareError;
  RecordingResult? _take;

  bool _mixing = false;
  double _mixProgress = 0;
  double _musicVolume = 0.55;
  double _voiceVolume = 1.8;
  double _syncMs = 0; // + moves the voice earlier

  Timer? _countTimer;
  Timer? _lyricTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _previewSub;

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  String get _meta => '${widget.track.language} · ${widget.track.uploader}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recorder
      ..onAutoStop = _onAutoStop
      ..onError = _recordingFailed;
    _previewSub = _player.stateStream.listen((s) {
      if (!mounted || _state != _RecState.recorded) return;
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (playing != _previewPlaying) setState(() => _previewPlaying = playing);
    });
    _prepare();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countTimer?.cancel();
    _lyricTimer?.cancel();
    _positionSub?.cancel();
    _previewSub?.cancel();
    _video?.dispose();
    unawaited(_recorder.dispose()); // discards an unfinished take
    unawaited(_player.pause());
    _wave.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android silences the mic for apps in the background, so end the take
    // instead of recording silence. iOS keeps recording (UIBackgroundModes audio).
    if (Platform.isAndroid &&
        state == AppLifecycleState.paused &&
        _state == _RecState.recording) {
      _stopRecording(reason: 'Recording stopped when the app went to the background.');
    }
  }

  // ---------- loading the track ----------

  Future<void> _prepare() async {
    try {
      final backing = _backing ??
          await KaraokeFiles.instance.prepareBacking(
            widget.track,
            onProgress: (p) {
              if (mounted) setState(() => _downloadProgress = p);
            },
          );
      final length = await _recorder.prepare(widget.track, backing);

      if (backing.video != null && _video == null) {
        final video = VideoPlayerController.file(
          backing.video!,
          // Don't take audio focus or change the audio session: the music
          // comes from SwaramPlayer, the video is only a silent guide.
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await video.initialize();
        await video.setVolume(0); // the sound comes from the backing audio
        _video = video;
      }
      await _video?.pause();
      await _video?.seekTo(Duration.zero);

      if (!mounted) return;
      setState(() {
        _backing = backing;
        if (length != null) _songLength = length;
        _preparing = false;
        _prepareError = null;
      });
    } on KaraokeException catch (e) {
      if (mounted) setState(() {
        _preparing = false;
        _prepareError = e.message;
      });
    } catch (e) {
      debugPrint('Prepare failed: $e');
      if (mounted) setState(() {
        _preparing = false;
        _prepareError = 'Could not open this song.';
      });
    }
  }

  void _retryPrepare() {
    setState(() {
      _preparing = true;
      _prepareError = null;
      _downloadProgress = null;
    });
    _prepare();
  }

  // ---------- recording ----------

  Future<void> _onRecordTap() async {
    switch (_state) {
      case _RecState.idle:
        if (_preparing) {
          _snack('Loading the karaoke track…');
          return;
        }
        if (_backing == null) {
          _snack(_prepareError ?? 'The track is not ready.');
          return;
        }
        if (!await _ensureMicPermission() || !mounted) return;
        _countIn ? _startCountdown() : _startRecording();
      case _RecState.countdown:
        _cancelCountdown();
      case _RecState.recording:
        _stopRecording();
      case _RecState.recorded:
        break;
    }
  }

  Future<bool> _ensureMicPermission() async {
    final result = await _recorder.requestPermission();
    if (result == MicPermission.granted) return true;
    if (!mounted) return false;
    if (result == MicPermission.permanentlyDenied) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: SwaramColors.card,
          title: const Text('Microphone is off',
              style: TextStyle(color: SwaramColors.text)),
          content: const Text(
              'Allow microphone access in Settings to record your singing.',
              style: TextStyle(color: SwaramColors.muted)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings')),
          ],
        ),
      );
      if (open == true) await openAppSettings();
    } else {
      _snack('Microphone access is needed to record your voice.');
    }
    return false;
  }

  void _startCountdown() {
    setState(() {
      _state = _RecState.countdown;
      _count = 3;
    });
    _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_count <= 1) {
        t.cancel();
        _startRecording();
      } else {
        setState(() => _count--);
      }
    });
  }

  void _cancelCountdown() {
    _countTimer?.cancel();
    setState(() => _state = _RecState.idle);
  }

  Future<void> _startRecording() async {
    setState(() {
      _state = _RecState.recording;
      _elapsed = Duration.zero;
      _line = 0;
    });
    try {
      await _recorder.start();
    } on KaraokeException catch (e) {
      _recordingFailed(e.message);
      return;
    }
    if (!mounted) return;
    _positionSub = _player.positionStream.listen((p) {
      if (!mounted || _state != _RecState.recording) return;
      _syncVideo(p);
      setState(() => _elapsed = p);
    });
    _lyricTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _line < widget.lyrics.length - 1) {
        setState(() => _line++);
      }
    });
  }

  /// Keeps the muted video within 200 ms of the music.
  void _syncVideo(Duration audio) {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;
    if (!video.value.isPlaying) video.play();
    final drift = (video.value.position - audio).inMilliseconds.abs();
    if (drift > 200) video.seekTo(audio);
  }

  Future<void> _stopRecording({String? reason}) async {
    _endRecordingTimers();
    try {
      final take = await _recorder.stop();
      if (take != null) _finishTake(take, reason: reason);
    } on KaraokeException catch (e) {
      _recordingFailed(e.message);
    }
  }

  void _onAutoStop(RecordingResult take) {
    _endRecordingTimers();
    _finishTake(
      take,
      reason: take.interrupted
          ? 'Recording stopped because of an interruption. Your take was kept.'
          : null,
    );
  }

  void _endRecordingTimers() {
    _lyricTimer?.cancel();
    _positionSub?.cancel();
    _positionSub = null;
    _video?.pause();
  }

  void _finishTake(RecordingResult take, {String? reason}) {
    if (!mounted) return;
    setState(() {
      _take = take;
      _state = _RecState.recorded;
      _previewPlaying = false;
      _elapsed = take.length;
    });
    if (reason != null) _snack(reason);
  }

  void _recordingFailed(String message) {
    _endRecordingTimers();
    if (!mounted) return;
    setState(() => _state = _RecState.idle);
    _snack(message);
    _prepare(); // reload the backing track at 0:00
  }

  Future<void> _reset() async {
    _countTimer?.cancel();
    _endRecordingTimers();
    await _recorder.cancel();
    final old = _take;
    if (!mounted) return;
    setState(() {
      _state = _RecState.idle;
      _elapsed = Duration.zero;
      _line = 0;
      _previewPlaying = false;
      _take = null;
    });
    await KaraokeFiles.instance.deleteIfExists(old?.vocalsPath);
    if (_backing != null) await _prepare();
  }

  // ---------- preview and mix ----------

  Future<void> _togglePreview() async {
    final take = _take;
    if (take == null) return;
    if (_player.currentTrack.value?.localPath == take.vocalsPath) {
      await _player.togglePlay();
      return;
    }
    if (!await File(take.vocalsPath).exists()) {
      _snack('Your recording is missing. Please record again.');
      return;
    }
    await _player.playFile(_fileTrack(take.vocalsPath, 'Your vocals'));
  }

  Future<void> _mix() async {
    if (_take == null || _mixing) return;
    await _player.pause();
    if (!mounted) return;
    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: SwaramColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mix levels',
                  style: TextStyle(
                      color: SwaramColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _LevelSlider(
                label: 'Music',
                value: _musicVolume,
                max: 2,
                text: '${(_musicVolume * 100).round()}%',
                onChanged: (v) => setSheet(() => _musicVolume = v),
              ),
              _LevelSlider(
                label: 'Voice',
                value: _voiceVolume,
                max: 3,
                text: '${(_voiceVolume * 100).round()}%',
                onChanged: (v) => setSheet(() => _voiceVolume = v),
              ),
              _LevelSlider(
                label: 'Voice timing',
                value: _syncMs,
                min: -300,
                max: 500,
                text: _syncMs == 0
                    ? 'in sync'
                    : '${_syncMs.round().abs()} ms ${_syncMs > 0 ? 'earlier' : 'later'}',
                onChanged: (v) => setSheet(() => _syncMs = v),
              ),
              const Text(
                'Sounding late? Move your voice earlier. Bluetooth headphones usually need 150–300 ms.',
                style: TextStyle(color: SwaramColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Create my song'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (go == true) await _runMix();
  }

  Future<void> _runMix() async {
    final take = _take!;
    setState(() {
      _mixing = true;
      _mixProgress = 0;
    });
    try {
      final output = await AudioMixer.mix(
        backingPath: take.backingPath,
        vocalsPath: take.vocalsPath,
        videoPath: take.videoPath,
        vocalShift: take.musicOffset + Duration(milliseconds: _syncMs.round()),
        musicVolume: _musicVolume,
        voiceVolume: _voiceVolume,
        expectedLength: take.length - take.musicOffset,
        onProgress: (p) {
          if (mounted) setState(() => _mixProgress = p);
        },
      );
      if (!mounted) return;
      setState(() => _mixing = false);
      await Navigator.of(context)
          .push(MixResultScreen.route(track: widget.track, output: output));
    } on KaraokeException catch (e) {
      if (!mounted) return;
      setState(() => _mixing = false);
      _snack(e.message);
    }
  }

  // ---------- helpers ----------

  Track _fileTrack(String path, String title) => Track(
        id: 'local_${path.hashCode}',
        title: title,
        language: widget.track.language,
        duration: _fmt(_elapsed),
        uploader: widget.track.uploader,
        localPath: path,
        genre: widget.track.genre,
        vibe: widget.track.vibe,
      );

  static Duration _parseLength(String text) {
    final parts = text.split(':').map(int.tryParse).toList();
    if (parts.length == 2 && parts[0] != null && parts[1] != null) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    }
    return const Duration(minutes: 4);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: SwaramColors.card,
          behavior: SnackBarBehavior.floating,
          content: Text(message, style: const TextStyle(color: SwaramColors.text)),
        ),
      );
  }

  String _fmt(Duration d) {
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$s';
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final recording = _state == _RecState.recording;

    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                children: [
                  _buildTopBar(recording),
                  const SizedBox(height: 8),
                  FadeSlide(
                    controller: _enter,
                    begin: 0.0,
                    end: 0.4,
                    child: _buildSongCard(recording),
                  ),
                  const SizedBox(height: 14),
                  // Expanded(
                  //   child: FadeSlide(
                  //     controller: _enter,
                  //     begin: 0.15,
                  //     end: 0.6,
                  //     child: _buildLyrics(),
                  //   ),
                  // ),
                  _video != null && _video!.value.isInitialized
                      ? Expanded(
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: _video!.value.aspectRatio,
                                child: VideoPlayer(_video!),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 124),
                  FadeSlide(
                    controller: _enter,
                    begin: 0.3,
                    end: 0.8,
                    child: _buildMeter(),
                  ),
                  const SizedBox(height: 14),
                  FadeSlide(
                    controller: _enter,
                    begin: 0.4,
                    end: 0.9,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _state == _RecState.recorded
                          ? _buildRecordedPanel()
                          : _buildControls(),
                    ),
                  ),
                ],
              ),
            ),
            if (_state == _RecState.countdown) _buildCountdown(),
            if (_preparing || _prepareError != null)
              _buildBusy(
                title: widget.track.isVideo
                    ? 'Preparing your video…'
                    : 'Loading the track…',
                progress: _downloadProgress,
                error: _prepareError,
                onRetry: _retryPrepare,
              ),
            if (_mixing)
              _buildBusy(
                title: 'Mixing your song…',
                progress: _mixProgress,
                onCancel: AudioMixer.cancel,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusy({
    required String title,
    double? progress,
    String? error,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    return Positioned.fill(
      child: ColoredBox(
        color: SwaramColors.bg.withValues(alpha: 0.9),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error == null)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: progress == 0 ? null : progress,
                      color: SwaramColors.amber,
                      strokeWidth: 4,
                    ),
                  )
                else
                  const Icon(Icons.error_outline_rounded,
                      color: SwaramColors.pink, size: 48),
                const SizedBox(height: 18),
                Text(
                  error ?? title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SwaramColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (error == null && progress != null && progress > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${(progress * 100).round()}%',
                        style: const TextStyle(color: SwaramColors.muted)),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onCancel != null)
                      TextButton(onPressed: onCancel, child: const Text('Cancel'))
                    else
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    if (error != null && onRetry != null)
                      FilledButton(
                          onPressed: onRetry, child: const Text('Try again')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool recording) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded,
              color: SwaramColors.text, size: 28),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (recording) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: SwaramColors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                recording ? 'RECORDING' : 'RECORD',
                style: TextStyle(
                  color: recording ? SwaramColors.pink : SwaramColors.muted,
                  fontSize: 12,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {}, // TODO: recording settings
          icon: const Icon(Icons.tune_rounded,
              color: SwaramColors.text, size: 24),
        ),
      ],
    );
  }

  Widget _buildSongCard(bool recording) {
    return AnimatedOpacity(
      opacity: recording ? 0.5 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SwaramColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: SwaramColors.amber,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.music_note,
                  color: SwaramColors.onAmber, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SwaramColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: SwaramColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PressScale(
              onTap: recording ? null : widget.onChangeSong,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SwaramColors.amber),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: SwaramColors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyrics() {
    final lines = widget.lyrics;
    final active = _state == _RecState.recording;

    String at(int i) => (i >= 0 && i < lines.length) ? lines[i] : '';

    Widget line(int offset) {
      final text = at(_line + offset);
      final current = offset == 0;
      return AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          color: current
              ? (active ? SwaramColors.amber : SwaramColors.text)
              : SwaramColors.muted.withAlpha(offset < 0 ? 90 : 150),
          fontSize: current ? 24 : 16,
          height: 1.25,
          fontWeight: current ? FontWeight.w800 : FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        child: Text(text),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: SwaramColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lyrics_outlined, color: SwaramColors.muted, size: 16),
              SizedBox(width: 6),
              Text(
                'LYRICS',
                style: TextStyle(
                  color: SwaramColors.muted,
                  fontSize: 11.5,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_line),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    line(-1),
                    const SizedBox(height: 14),
                    line(0),
                    const SizedBox(height: 14),
                    line(1),
                    const SizedBox(height: 10),
                    line(2),
                  ],
                ),
              ),
            ),
          ),
          if (_state == _RecState.idle)
            const Text(
              'Lyrics scroll by themselves while you record.',
              style: TextStyle(color: SwaramColors.muted, fontSize: 12.5),
            ),
        ],
      ),
    );
  }

  Widget _buildMeter() {
    final recording = _state == _RecState.recording;
    final progress = _songLength.inMilliseconds == 0
        ? 0.0
        : _elapsed.inMilliseconds / _songLength.inMilliseconds;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _fmt(_elapsed),
              style: TextStyle(
                color: recording ? SwaramColors.text : SwaramColors.muted,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '  /  ${_fmt(_songLength)}',
              style: const TextStyle(color: SwaramColors.muted, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Wave(controller: _wave, active: recording),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 5,
            color: SwaramColors.amber,
            backgroundColor: SwaramColors.border,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final recording = _state == _RecState.recording;
    final counting = _state == _RecState.countdown;

    final label = recording
        ? 'Tap to stop'
        : (counting ? 'Tap to cancel' : 'Tap to record');

    return Column(
      key: const ValueKey('controls'),
      children: [
        if (_state == _RecState.idle) ...[
          const _Tip(
              text: 'Use headphones so the music is not picked up by the mic.'),
          const SizedBox(height: 14),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SideButton(
              icon: Icons.replay_rounded,
              label: 'Restart',
              enabled: recording,
              onTap: _reset,
            ),
            _RecordButton(
              recording: recording || counting,
              onTap: _onRecordTap,
            ),
            _SideButton(
              icon: Icons.timer_outlined,
              label: 'Count-in',
              active: _countIn,
              enabled: _state == _RecState.idle,
              onTap: () => setState(() => _countIn = !_countIn),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: SwaramColors.muted, fontSize: 13.5)),
      ],
    );
  }

  Widget _buildRecordedPanel() {
    return Column(
      key: const ValueKey('recorded'),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SwaramColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              PressScale(
                onTap: _togglePreview,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: SwaramColors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _previewPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: SwaramColors.onAmber,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your recording',
                      style: TextStyle(
                        color: SwaramColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt(_elapsed)} · tap to listen',
                      style: const TextStyle(
                          color: SwaramColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const _StaticWave(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _PillButton(
                label: 'Re-record',
                icon: Icons.refresh_rounded,
                outlined: true,
                onTap: _reset,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PillButton(
                label: 'Mix',
                icon: Icons.auto_awesome_rounded,
                onTap: _mix,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _cancelCountdown,
        child: Container(
          color: SwaramColors.bg.withAlpha(235),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GET READY',
                style: TextStyle(
                  color: SwaramColors.muted,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.5, end: 1.0).animate(
                      CurvedAnimation(
                          parent: animation, curve: Curves.easeOutBack),
                    ),
                    child: child,
                  ),
                ),
                child: Text(
                  '$_count',
                  key: ValueKey(_count),
                  style: const TextStyle(
                    color: SwaramColors.amber,
                    fontSize: 140,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tap anywhere to cancel',
                style: TextStyle(color: SwaramColors.muted, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= small widgets =======================

/// Bars that move while recording and rest flat otherwise.
class _Wave extends StatelessWidget {
  final Animation<double> controller;
  final bool active;
  const _Wave({required this.controller, required this.active});

  static final List<double> _shape =
      List.generate(34, (i) => 0.45 + 0.55 * math.sin(i * 1.1).abs());

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < _shape.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 5,
                  height: active
                      ? 8 + 46 * _shape[i] * (0.35 + 0.65 * math.sin(t * 2 + i * 0.7).abs())
                      : 5 + 5 * _shape[i],
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: active ? SwaramColors.pink : SwaramColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StaticWave extends StatelessWidget {
  const _StaticWave();

  static final List<double> _bars = () {
    final r = math.Random(7);
    return List.generate(14, (_) => 0.25 + 0.75 * r.nextDouble());
  }();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final h in _bars)
            Container(
              width: 3,
              height: 6 + 28 * h,
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                color: SwaramColors.pinkSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatefulWidget {
  final bool recording;
  final VoidCallback onTap;
  const _RecordButton({required this.recording, required this.onTap});

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.recording)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                final d = 84 + 36 * t;
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          SwaramColors.pink.withAlpha(((1 - t) * 170).round()),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          PressScale(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: SwaramColors.pink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SwaramColors.pink.withAlpha(widget.recording ? 110 : 60),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                  key: ValueKey(widget.recording),
                  color: const Color(0xFF2A0A18),
                  size: 42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool active;
  final VoidCallback onTap;

  const _SideButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? SwaramColors.amber : SwaramColors.text;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SwaramColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? SwaramColors.amber : SwaramColors.border,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? SwaramColors.amber : SwaramColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? SwaramColors.amber : SwaramColors.onAmber;
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : SwaramColors.amber,
          borderRadius: BorderRadius.circular(30),
          border: outlined ? Border.all(color: SwaramColors.amber) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 21),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: SwaramColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.headphones_rounded,
              color: SwaramColors.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: SwaramColors.textSoft, fontSize: 12.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}



class _LevelSlider extends StatelessWidget {
  final String label;
  final String text;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _LevelSlider({
    required this.label,
    required this.text,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style: const TextStyle(
                  color: SwaramColors.textSoft, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: SwaramColors.amber,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 92,
          child: Text(text,
              textAlign: TextAlign.end,
              style: const TextStyle(color: SwaramColors.muted, fontSize: 12.5)),
        ),
      ],
    );
  }
}
