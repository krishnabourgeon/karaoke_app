import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/video_player_screen.dart';
import 'library_store.dart';
import 'song_detail_screen.dart';
import 'upload_screen.dart';

/// Shows every song the user marked with the heart, newest first.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  List<Track> _favorites() {
    final byId = {for (final t in LibraryStore.instance.tracks) t.id: t};
    final ids = FavoritesStore.instance.ids.value.toList().reversed;
    return [
      for (final id in ids)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  // void _openSong(List<Track> list, int index) {
  //   Navigator.of(context).push(
  //     SongDetailScreen.route(
  //       tracks: list,
  //       index: index,
  //       onDownload: _handleDownload,
  //     ),
  //   );
  // }

  void _openSong(List<Track> list, int index) {
  final track = list[index];

  // Videos open in the video player.
  if (track.isVideo) {
    Navigator.of(context).push(VideoPlayerScreen.route(track, onDownload: _handleDownload));
    return;
  }

  // Audio: queue only audio tracks, so Next/Previous skip videos.
  final audioTracks = list.where((t) => !t.isVideo).toList();
  Navigator.of(context).push(
    SongDetailScreen.route(
      tracks: audioTracks,
      index: audioTracks.indexWhere((t) => t.id == track.id),
      onDownload: _handleDownload,
    ),
  );
}

  Future<void> _handleDownload(Track track) async {
    final result = await LibraryStore.instance.download(track);
    if (!mounted) return;
    switch (result) {
      case DownloadResult.saved:
        _snack('Saved "${track.title}" to your device.');
      case DownloadResult.cancelled:
        _snack('Download cancelled.');
      case DownloadResult.notEnoughPoints:
        _snack('Not enough points. Upload a karaoke to earn more.');
      case DownloadResult.failed:
        _snack('Could not save this track. Try again.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: SwaramColors.card,
          behavior: SnackBarBehavior.floating,
          content:
              Text(message, style: const TextStyle(color: SwaramColors.text)),
        ),
      );
  }

  void _goHome() => Navigator.of(context)
      .pushNamedAndRemoveUntil('/home', (route) => false);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LibraryStore.instance,
        FavoritesStore.instance.ids,
      ]),
      builder: (context, _) {
        final favorites = _favorites();

        return Scaffold(
          backgroundColor: SwaramColors.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: FadeSlide(
                    controller: _enter,
                    begin: 0.0,
                    end: 0.5,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Library',
                                style: TextStyle(
                                  color: SwaramColors.text,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                favorites.isEmpty
                                    ? 'Your favourite karaoke'
                                    : '${favorites.length} favourite ${favorites.length == 1 ? 'song' : 'songs'}',
                                style: const TextStyle(
                                  color: SwaramColors.muted,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (favorites.isNotEmpty)
                          PressScale(
                            //onTap: () => _openSong(favorites, 0),
                            onTap: () {
                              final first = favorites.indexWhere((t) => !t.isVideo);
                              if (first != -1) _openSong(favorites, first);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: SwaramColors.amber,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      color: SwaramColors.onAmber, size: 22),
                                  SizedBox(width: 4),
                                  Text(
                                    'Play all',
                                    style: TextStyle(
                                      color: SwaramColors.onAmber,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: favorites.isEmpty
                      ? _EmptyState(onBrowse: _goHome)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                          itemCount: favorites.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final track = favorites[i];
                            return TweenAnimationBuilder<double>(
                              key: ValueKey(track.id),
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(
                                  milliseconds: 300 + (i < 6 ? i : 6) * 70),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, 14 * (1 - v)),
                                  child: child,
                                ),
                              ),
                              child: _FavoriteTile(
                                track: track,
                                color: trackColor(track),
                                onTap: () => _openSong(favorites, i),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SwaramBottomNav(
            current: SwaramTab.library,
            onHome: _goHome,
            // onSearch: _goHome,
            onSearch: () => Navigator.of(context).pushReplacementNamed('/search'),
            onUpload: () => Navigator.of(context).push(UploadScreen.route()),
            onProfile: () =>
                Navigator.of(context).pushReplacementNamed('/profile'),
          ),
        );
      },
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final Track track;
  final Color color;
  final VoidCallback onTap;

  const _FavoriteTile({
    required this.track,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        decoration: BoxDecoration(
          color: SwaramColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.music_note,
                  color: SwaramColors.onAmber, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SwaramColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${track.language} · ${track.duration} · ${track.uploader}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SwaramColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                FavoritesStore.instance.toggle(track.id);
              },
              icon: const Icon(Icons.favorite,
                  color: SwaramColors.pink, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: SwaramColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border,
                  color: SwaramColors.pink, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No favourites yet',
              style: TextStyle(
                color: SwaramColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the heart on a song and it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SwaramColors.muted,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            PressScale(
              onTap: onBrowse,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: SwaramColors.amber),
                ),
                child: const Text(
                  'Browse songs',
                  style: TextStyle(
                    color: SwaramColors.amber,
                    fontSize: 15,
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
}