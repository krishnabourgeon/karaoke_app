import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/view/common_widgets/record_launcher.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'library_store.dart';
import 'song_detail_screen.dart';

/// Video version of [SongDetailScreen]: same layout, with the video
/// shown where the spinning record is.
class VideoPlayerScreen  extends  StatefulWidget {
  final Track track;
  final void Function(Track track)? onDownload;

  const VideoPlayerScreen({super.key, required this.track, this.onDownload});

  /// Slides the screen up from the bottom, like the song screen.
  static Route<void> route(Track track,
      {void Function(Track track)? onDownload}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) =>
          VideoPlayerScreen(track: track, onDownload: onDownload),
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
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver{
  late final VideoPlayerController _video;
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  bool _ready = false;
  String? _error;
  double? _dragValue;
  Duration? _resumeAt;
bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
if (SwaramPlayer.instance.currentTrack.value?.id == widget.track.id) {
  _resumeAt = SwaramPlayer.instance.position;
}
    SwaramPlayer.instance.pause(); // stop any audio that is playing
    final t = widget.track;
    // _video = t.localPath != null
    //     ? VideoPlayerController.file(File(t.localPath!))
    //     : VideoPlayerController.networkUrl(Uri.parse(t.audioUrl));
    _video = t.localPath != null
    ? VideoPlayerController.file(
        File(t.localPath!),
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
      )
    : VideoPlayerController.networkUrl(
        Uri.parse(t.audioUrl),
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
      );
      _video.addListener(_syncWakelock);
    _init();
  }

  Future<void> _init() async {
    try {
      await _video.initialize();
      LibraryStore.instance
          .updateDuration(widget.track.id, _video.value.duration);
      if (!mounted) return;
      setState(() => _ready = true);
      if (_resumeAt != null) await _video.seekTo(_resumeAt!);
      await _video.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not play this video.');
    }
  }

  
    @override
  void dispose() {
    WakelockPlus.disable();
WidgetsBinding.instance.removeObserver(this);
    _handOffToAudio(); // back button: keep the song going as audio
    _video.removeListener(_syncWakelock);
WakelockPlus.disable();
    _video.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _handOffToAudio(); // app minimised / phone locked
    } else if (state == AppLifecycleState.resumed) {
      _takeBackFromAudio();
    }
  }

  /// Keep the screen on only while the video is actually playing.
  void _syncWakelock() {
    WakelockPlus.toggle(enable: _video.value.isPlaying);
  }

  /// Video stops, audio continues from the same point (shows the notification).
  void _handOffToAudio() {
    if (!_ready || _handedOff || !_video.value.isPlaying) return;
    _handedOff = true;
    final position = _video.value.position;
    _video.pause();
    SwaramPlayer.instance.playTrackAt(widget.track, position);
  }

  /// User came back to the video screen: audio stops, video continues.
  Future<void> _takeBackFromAudio() async {
    if (!_handedOff) return;
    _handedOff = false;
    final audio = SwaramPlayer.instance;
    // They may have skipped to another song from the notification.
    if (audio.currentTrack.value?.id != widget.track.id) return;
    final position = audio.position;
    final wasPlaying = audio.playing;
    await audio.pause();
    await _video.seekTo(position);
    if (wasPlaying) await _video.play();
  }


  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: SwaramColors.card,
          behavior: SnackBarBehavior.floating,
          content: Text(message,
              style: const TextStyle(color: SwaramColors.text)),
        ),
      );
  }

  String _fmt(Duration d) {
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }

  void _togglePlay() {
    if (!_ready) return;
    final v = _video.value;
    if (v.isPlaying) {
      _video.pause();
    } else {
      if (v.position >= v.duration) _video.seekTo(Duration.zero);
      _video.play();
    }
  }

  void _skip(int seconds) {
    if (!_ready) return;
    final v = _video.value;
    var target = v.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > v.duration) target = v.duration;
    _video.seekTo(target);
  }

  void _openFullscreen() {
    if (!_ready) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _FullscreenVideo(controller: _video),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;

    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              FadeSlide(
                controller: _enter,
                begin: 0.0,
                end: 0.5,
                child: _buildVideo(track),
              ),
              const SizedBox(height: 28),
              FadeSlide(
                controller: _enter,
                begin: 0.2,
                end: 0.6,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SwaramColors.text,
                              fontSize: 26,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${track.language} · ${track.uploader}',
                            style: const TextStyle(
                              color: SwaramColors.muted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    HeartButton(trackId: track.id),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FadeSlide(
                controller: _enter,
                begin: 0.3,
                end: 0.7,
                child: _buildSeekBar(),
              ),
              const SizedBox(height: 6),
              FadeSlide(
                controller: _enter,
                begin: 0.4,
                end: 0.8,
                child: _buildControls(),
              ),
              const SizedBox(height: 26),
              FadeSlide(
                controller: _enter,
                begin: 0.5,
                end: 0.9,
                child: _buildDownloadButton(track),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: SwaramColors.text, size: 34),
        ),
        const Expanded(
          child: Text(
            'NOW PLAYING',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SwaramColors.muted,
              fontSize: 12,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Pause the video first so its sound doesn't play over the karaoke track.
        SingButton(track: widget.track, beforeOpen: _video.pause),
        IconButton(
          onPressed: () => _toast('Share is not set up yet.'),
          icon: const Icon(Icons.share_outlined,
              color: SwaramColors.text, size: 24),
        ),
      ],
    );
  }

  Widget _buildVideo(Track track) {
    final color = trackColor(track);

    final Widget content;
    if (_error != null) {
      content = Center(
        child: Text(_error!,
            style: const TextStyle(color: SwaramColors.muted, fontSize: 15)),
      );
    } else if (!_ready) {
      content = const Center(
        child: CircularProgressIndicator(color: SwaramColors.amber),
      );
    } else {
      content = GestureDetector(
        onTap: _togglePlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _video.value.aspectRatio,
                child: VideoPlayer(_video),
              ),
            ),
            // Big play icon while paused.
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _video,
              builder: (context, v, _) => AnimatedOpacity(
                opacity: v.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white70, size: 64),
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: IconButton(
                onPressed: _openFullscreen,
                icon: const Icon(Icons.fullscreen_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: color.withAlpha(60), blurRadius: 44, spreadRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(color: Colors.black, child: content),
        ),
      ),
    );
  }

  Widget _buildSeekBar() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _video,
      builder: (context, v, _) {
        final total = _ready ? v.duration : Duration.zero;
        var position = v.position;
        if (position > total) position = total;

        final max = total.inMilliseconds.toDouble();
        final value = (_dragValue ?? position.inMilliseconds.toDouble())
            .clamp(0.0, max > 0 ? max : 1.0)
            .toDouble();

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: SwaramColors.amber,
                inactiveTrackColor: SwaramColors.border,
                thumbColor: SwaramColors.amber,
                disabledActiveTrackColor: SwaramColors.border,
                disabledInactiveTrackColor: SwaramColors.border,
                disabledThumbColor: SwaramColors.border,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                min: 0,
                max: max > 0 ? max : 1,
                value: value,
                onChanged:
                    max > 0 ? (x) => setState(() => _dragValue = x) : null,
                onChangeEnd: (x) {
                  _video.seekTo(Duration(milliseconds: x.round()));
                  setState(() => _dragValue = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(Duration(milliseconds: value.round())),
                    style:
                        const TextStyle(color: SwaramColors.muted, fontSize: 13),
                  ),
                  Text(
                    _fmt(total),
                    style:
                        const TextStyle(color: SwaramColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => _skip(-10),
          icon: const Icon(Icons.replay_10_rounded,
              color: SwaramColors.text, size: 40),
        ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _video,
          builder: (context, v, _) {
            final busy = !_ready || v.isBuffering;
            final completed =
                _ready && !v.isPlaying && v.position >= v.duration;

            final Widget icon;
            if (busy && _error == null) {
              icon = const SizedBox(
                key: ValueKey('busy'),
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: SwaramColors.onAmber,
                ),
              );
            } else {
              final data = completed
                  ? Icons.replay_rounded
                  : (v.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded);
              icon = Icon(data,
                  key: ValueKey(data), color: SwaramColors.onAmber, size: 44);
            }

            return PressScale(
              onTap: _togglePlay,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: SwaramColors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SwaramColors.amber.withAlpha(v.isPlaying ? 90 : 0),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: icon,
                ),
              ),
            );
          },
        ),
        IconButton(
          onPressed: () => _skip(10),
          icon: const Icon(Icons.forward_10_rounded,
              color: SwaramColors.text, size: 40),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(Track track) {
    return PressScale(
      onTap: () => widget.onDownload?.call(track),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: SwaramColors.amber),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_download_outlined,
                color: SwaramColors.amber, size: 22),
            const SizedBox(width: 8),
            ListenableBuilder(
              listenable: LibraryStore.instance,
              builder: (context, _) => Text(
                LibraryStore.instance.isDownloaded(track.id)
                    ? 'Downloaded · save again'
                    : 'Download · ${track.points} pts',
                style: const TextStyle(
                  color: SwaramColors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Landscape fullscreen view that shares the same controller,
/// so playback continues where it was.
class _FullscreenVideo extends StatefulWidget {
  final VideoPlayerController controller;
  const _FullscreenVideo({required this.controller});

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => c.value.isPlaying ? c.pause() : c.play(),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: SwaramColors.amber,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.fullscreen_exit_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
