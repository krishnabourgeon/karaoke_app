import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/song_detail_screen.dart';
import 'package:karaoke_app/view/video_player_screen.dart';

/// "Now playing" bar shown above the bottom nav while a song is loaded.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  void _open(BuildContext context, Track track) {
    if (track.isVideo) {
      Navigator.of(context).push(VideoPlayerScreen.route(track));
      return;
    }
    final queue = SwaramPlayer.instance.queue;
    final i = queue.indexWhere((t) => t.id == track.id);
    Navigator.of(context).push(SongDetailScreen.route(
      tracks: i == -1 ? [track] : queue,
      index: i == -1 ? 0 : i,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final player = SwaramPlayer.instance;

    return ValueListenableBuilder<Track?>(
      valueListenable: player.currentTrack,
      builder: (context, track, _) {
        if (track == null) return const SizedBox.shrink();
        final color = trackColor(track);

        return GestureDetector(
          onTap: () => _open(context, track),
          child: Container(
            // Bottom gap leaves room for the round upload button.
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 34),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: SwaramColors.cardHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SwaramColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          track.isVideo ? Icons.videocam : Icons.music_note,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SwaramColors.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              track.uploader,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SwaramColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        color: SwaramColors.text,
                        onPressed: player.previous,
                      ),
                      StreamBuilder<PlayerState>(
                        stream: player.stateStream,
                        builder: (context, snap) {
                          final s = snap.data;
                          final loading =
                              s?.processingState == ProcessingState.loading ||
                                  s?.processingState ==
                                      ProcessingState.buffering;
                          final playing = s != null &&
                              s.playing &&
                              s.processingState != ProcessingState.completed;
                          if (loading) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SwaramColors.amber,
                                ),
                              ),
                            );
                          }
                          return IconButton(
                            icon: Icon(playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled),
                            iconSize: 36,
                            color: SwaramColors.amber,
                            onPressed: player.togglePlay,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        color: SwaramColors.text,
                        onPressed: player.next,
                      ),
                    ],
                  ),
                ),
                _MiniProgress(color: color),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final Color color;
  const _MiniProgress({required this.color});

  @override
  Widget build(BuildContext context) {
    final player = SwaramPlayer.instance;
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durSnap) {
        final total = durSnap.data?.inMilliseconds ?? 0;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, posSnap) {
            final pos = posSnap.data?.inMilliseconds ?? 0;
            return LinearProgressIndicator(
              value: total > 0 ? (pos / total).clamp(0.0, 1.0) : 0,
              minHeight: 2,
              backgroundColor: SwaramColors.border,
              color: color,
            );
          },
        );
      },
    );
  }
}