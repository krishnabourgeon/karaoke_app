import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:karaoke_app/view/common_widgets/record_launcher.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'library_store.dart';


class SongDetailScreen extends StatefulWidget {
  final List<Track> tracks;
  final int index;
  final void Function(Track track)? onDownload;

  const SongDetailScreen({
    super.key,
    required this.tracks,
    required this.index,
    this.onDownload,
  });

  /// Slides the screen up from the bottom.
  static Route<void> route({
    required List<Track> tracks,
    required int index,
    void Function(Track track)? onDownload,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => SongDetailScreen(
        tracks: tracks,
        index: index,
        onDownload: onDownload,
      ),
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
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen>
    with TickerProviderStateMixin {
  final SwaramPlayer _player = SwaramPlayer.instance;

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  StreamSubscription<PlayerState>? _stateSub;
  double? _dragValue;

  @override
  void initState() {
    super.initState();

    final selected = widget.tracks[widget.index];
    if (_player.currentTrack.value?.id == selected.id) {
      // Same song already playing: keep it going, just refresh the queue.
      _player.updateQueue(widget.tracks);
    } else {
      _player.playQueue(widget.tracks, widget.index);
    }

    _stateSub = _player.stateStream.listen((s) {
      final active = s.playing &&
          s.processingState != ProcessingState.completed &&
          s.processingState != ProcessingState.idle;
      if (active) {
        if (!_spin.isAnimating) _spin.repeat();
      } else {
        _spin.stop();
      }
    });

    _player.error.addListener(_onError);
  }

  @override
  void dispose() {
    _player.error.removeListener(_onError);
    _stateSub?.cancel();
    _spin.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onError() {
    final message = _player.error.value;
    if (message == null || !mounted) return;
    _toast(message);
    _player.error.value = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final art = math.min(constraints.maxWidth - 72, 300.0);

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ValueListenableBuilder<Track?>(
                valueListenable: _player.currentTrack,
                builder: (context, current, _) {
                  final track = current ?? widget.tracks[widget.index];
                  final color = trackColor(track);

                  return Column(
                    children: [
                      _buildTopBar(track),
                      const SizedBox(height: 20),
                      FadeSlide(
                        controller: _enter,
                        begin: 0.0,
                        end: 0.5,
                        child: SizedBox(
                          width: art,
                          height: art,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: art * 0.9,
                                height: art * 0.9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withAlpha(60),
                                      blurRadius: 44,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              RotationTransition(
                                turns: _spin,
                                child: CustomPaint(
                                  size: Size.square(art),
                                  painter: _RecordPainter(color),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        child: PressScale(
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(Track track) {
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
        SingButton(track: track),
        IconButton(
          onPressed: () => _toast('Share is not set up yet.'),
          icon: const Icon(Icons.share_outlined,
              color: SwaramColors.text, size: 24),
        ),
      ],
    );
  }

  Widget _buildSeekBar() {
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, durationSnap) {
        final total = durationSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, positionSnap) {
            var position = positionSnap.data ?? Duration.zero;
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
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    min: 0,
                    max: max > 0 ? max : 1,
                    value: value,
                    onChanged: max > 0
                        ? (v) => setState(() => _dragValue = v)
                        : null,
                    onChangeEnd: (v) {
                      _player.seek(Duration(milliseconds: v.round()));
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
                        style: const TextStyle(
                            color: SwaramColors.muted, fontSize: 13),
                      ),
                      Text(
                        _fmt(total),
                        style: const TextStyle(
                            color: SwaramColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // ValueListenableBuilder<bool>(
        //   valueListenable: _player.shuffle,
        //   builder: (context, on, _) => IconButton(
        //     onPressed: _player.toggleShuffle,
        //     icon: Icon(
        //       Icons.shuffle_rounded,
        //       color: on ? SwaramColors.amber : SwaramColors.muted,
        //       size: 26,
        //     ),
        //   ),
        // ),
        IconButton(
          onPressed: _player.previous,
          icon: const Icon(Icons.skip_previous_rounded,
              color: SwaramColors.text, size: 42),
        ),
        _PlayButton(player: _player),
        IconButton(
          onPressed: _player.next,
          icon: const Icon(Icons.skip_next_rounded,
              color: SwaramColors.text, size: 42),
        ),
        // ValueListenableBuilder<bool>(
        //   valueListenable: _player.repeatOne,
        //   builder: (context, on, _) => IconButton(
        //     onPressed: _player.toggleRepeat,
        //     icon: Icon(
        //       on ? Icons.repeat_one_rounded : Icons.repeat_rounded,
        //       color: on ? SwaramColors.amber : SwaramColors.muted,
        //       size: 26,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final SwaramPlayer player;
  const _PlayButton({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.stateStream,
      builder: (context, snap) {
        final state = snap.data;
        final processing = state?.processingState;
        final playing = state?.playing ?? false;
        final busy = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;
        final completed = processing == ProcessingState.completed;

        final Widget icon;
        if (busy) {
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
              : (playing ? Icons.pause_rounded : Icons.play_arrow_rounded);
          icon = Icon(data,
              key: ValueKey(data), color: SwaramColors.onAmber, size: 44);
        }

        return PressScale(
          onTap: player.togglePlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: SwaramColors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SwaramColors.amber.withAlpha(playing ? 90 : 0),
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
    );
  }
}

class HeartButton extends StatefulWidget {
  final String trackId;
  const HeartButton({super.key, required this.trackId});

  @override
  State<HeartButton> createState() => HeartButtonState();
}

class HeartButtonState extends State<HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 60,
    ),
  ]).animate(_pop);

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _toggle() {
    final store = FavoritesStore.instance;
    final wasFavorite = store.isFavorite(widget.trackId);
    store.toggle(widget.trackId);
    HapticFeedback.selectionClick();
    if (!wasFavorite) _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesStore.instance.ids,
      builder: (context, ids, _) {
        final favorite = ids.contains(widget.trackId);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: SwaramColors.card,
                shape: BoxShape.circle,
              ),
              child: Icon(
                favorite ? Icons.favorite : Icons.favorite_border,
                color: favorite ? SwaramColors.pink : SwaramColors.muted,
                size: 26,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecordPainter extends CustomPainter {
  final Color labelColor;
  _RecordPainter(this.labelColor);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0B0616));

    for (final f in [0.94, 0.86, 0.78, 0.7, 0.62, 0.54]) {
      canvas.drawCircle(
        c,
        r * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = SwaramColors.border,
      );
    }

    // Light sweep, so the spin is visible.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi / 4,
      true,
      Paint()..color = Colors.white.withAlpha(16),
    );

    canvas.drawCircle(c, size.width * 0.17, Paint()..color = labelColor);
    canvas.drawCircle(
        c, size.width * 0.026, Paint()..color = const Color(0xFF0B0616));
  }

  @override
  bool shouldRepaint(covariant _RecordPainter old) =>
      old.labelColor != labelColor;
}