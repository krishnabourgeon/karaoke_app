import 'package:flutter/material.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'library_store.dart';
import 'song_detail_screen.dart';
import 'upload_screen.dart';
import 'video_player_screen.dart';

enum _Category { language, genre, vibe }

extension _CategoryX on _Category {
  String get label {
    switch (this) {
      case _Category.language:
        return 'Language';
      case _Category.genre:
        return 'Genre';
      case _Category.vibe:
        return 'Vibe';
    }
  }

  IconData get icon {
    switch (this) {
      case _Category.language:
        return Icons.translate_rounded;
      case _Category.genre:
        return Icons.library_music_outlined;
      case _Category.vibe:
        return Icons.auto_awesome_rounded;
    }
  }
}

/// Search by text, or browse by Language, Genre and Vibe.
/// Filters can be combined, for example Malayalam + Romantic + 90's vibe.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  static const _tileColors = [
    SwaramColors.amber,
    SwaramColors.pinkSoft,
    SwaramColors.teal,
    SwaramColors.muted,
  ];

  final TextEditingController _controller = TextEditingController();
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  String _query = '';
  _Category _tab = _Category.language;
  String? _language;
  String? _genre;
  String? _vibe;

  @override
  void dispose() {
    _controller.dispose();
    _enter.dispose();
    super.dispose();
  }

  // ---------- data helpers ----------

  String _s(String? v) => (v ?? '').trim();

  String _valueOf(Track t, _Category c) {
    switch (c) {
      case _Category.language:
        return _s(t.language);
      case _Category.genre:
        return _s(t.genre);
      case _Category.vibe:
        return _s(t.vibe);
    }
  }

  String? _selected(_Category c) {
    switch (c) {
      case _Category.language:
        return _language;
      case _Category.genre:
        return _genre;
      case _Category.vibe:
        return _vibe;
    }
  }

  void _select(_Category c, String? value) {
    setState(() {
      switch (c) {
        case _Category.language:
          _language = value;
        case _Category.genre:
          _genre = value;
        case _Category.vibe:
          _vibe = value;
      }
    });
  }

  bool get _hasFilters => _language != null || _genre != null || _vibe != null;
  bool get _browsing => _query.trim().isEmpty && !_hasFilters;

  /// Values used in [c] with how many songs have each, most songs first.
  List<MapEntry<String, int>> _options(_Category c) {
    final counts = <String, int>{};
    for (final t in LibraryStore.instance.tracks) {
      final v = _valueOf(t, c);
      if (v.isEmpty) continue;
      counts[v] = (counts[v] ?? 0) + 1;
    }
    return counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
  }

  List<Track> _results() {
    final q = _query.trim().toLowerCase();
    return LibraryStore.instance.tracks.where((t) {
      if (_language != null && _valueOf(t, _Category.language) != _language) {
        return false;
      }
      if (_genre != null && _valueOf(t, _Category.genre) != _genre) {
        return false;
      }
      if (_vibe != null && _valueOf(t, _Category.vibe) != _vibe) {
        return false;
      }
      if (q.isEmpty) return true;
      final haystack = [
        t.title,
        t.uploader,
        _s(t.language),
        _s(t.genre),
        _s(t.vibe),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _clearAll() {
    _controller.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _query = '';
      _language = null;
      _genre = null;
      _vibe = null;
    });
  }

  // ---------- actions ----------

  void _openTrack(Track track, List<Track> results) {
    if (track.isVideo) {
      Navigator.of(context).push(
        VideoPlayerScreen.route(track, onDownload: _handleDownload),
      );
      return;
    }
    // Audio queue: the audio songs in the current results.
    final queue = results.where((t) => !t.isVideo).toList();
    final index = queue.indexWhere((t) => t.id == track.id);
    Navigator.of(context).push(
      SongDetailScreen.route(
        tracks: queue,
        index: index < 0 ? 0 : index,
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

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LibraryStore.instance,
      builder: (context, _) {
        final browsing = _browsing;
        final results = browsing ? const <Track>[] : _results();

        return Scaffold(
          backgroundColor: SwaramColors.bg,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (browsing) ..._browseSlivers() else ..._resultSlivers(results),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SwaramBottomNav(
            current: SwaramTab.search,
            onHome: _goHome,
            onSearch: () {},
            onUpload: () => Navigator.of(context).push(UploadScreen.route()),
            onLibrary: () =>
                Navigator.of(context).pushReplacementNamed('/library'),
            onProfile: () =>
                Navigator.of(context).pushReplacementNamed('/profile'),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: FadeSlide(
        controller: _enter,
        begin: 0.0,
        end: 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search',
              style: TextStyle(
                color: SwaramColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: SwaramColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SwaramColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: SwaramColors.muted, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      cursorColor: SwaramColors.amber,
                      style: const TextStyle(
                          color: SwaramColors.text, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Songs, artists, genre or vibe',
                        hintStyle:
                            TextStyle(color: SwaramColors.muted, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close,
                          color: SwaramColors.muted, size: 20),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- browse mode: pick a category, then a tile -----

  List<Widget> _browseSlivers() {
    final options = _options(_tab);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: FadeSlide(
            controller: _enter,
            begin: 0.2,
            end: 0.7,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: SwaramColors.card,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                children: [
                  for (final c in _Category.values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _tab = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c == _tab
                                ? SwaramColors.amber
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            c.label,
                            style: TextStyle(
                              color: c == _tab
                                  ? SwaramColors.onAmber
                                  : SwaramColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (options.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
            child: Text(
              'No ${_tab.label.toLowerCase()} tags yet. Pick one when you upload a song.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: SwaramColors.muted, fontSize: 14.5, height: 1.4),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final entry = options[i];
                return TweenAnimationBuilder<double>(
                  key: ValueKey('${_tab.name}-${entry.key}'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 280 + (i < 8 ? i : 8) * 50),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
                  ),
                  child: _CategoryTile(
                    label: entry.key,
                    count: entry.value,
                    icon: _tab.icon,
                    color: _tileColors[i % _tileColors.length],
                    onTap: () => _select(_tab, entry.key),
                  ),
                );
              },
              childCount: options.length,
            ),
          ),
        ),
    ];
  }

  // ----- result mode: filters + matching songs -----

  List<Widget> _resultSlivers(List<Track> results) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in _Category.values) _buildFilterRow(c),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${results.length} ${results.length == 1 ? 'song' : 'songs'}',
                      style: const TextStyle(
                        color: SwaramColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: SwaramColors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (results.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
            child: Column(
              children: const [
                Icon(Icons.search_off, color: SwaramColors.muted, size: 40),
                SizedBox(height: 12),
                Text(
                  'No songs found',
                  style: TextStyle(
                    color: SwaramColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Try fewer filters or another word.',
                  style: TextStyle(color: SwaramColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final track = results[i];
              return TweenAnimationBuilder<double>(
                key: ValueKey(track.id),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + (i < 6 ? i : 6) * 60),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - v)),
                    child: child,
                  ),
                ),
                child: _ResultTile(
                  track: track,
                  color: trackColor(track),
                  genre: _s(track.genre),
                  vibe: _s(track.vibe),
                  onTap: () => _openTrack(track, results),
                  onDownload: () => _handleDownload(track),
                ),
              );
            },
          ),
        ),
    ];
  }

  Widget _buildFilterRow(_Category c) {
    final options = _options(c);
    if (options.isEmpty) return const SizedBox.shrink();
    final selected = _selected(c);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Text(
              c.label.toUpperCase(),
              style: const TextStyle(
                color: SwaramColors.muted,
                fontSize: 11.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: selected == null,
                  onTap: () => _select(c, null),
                ),
                for (final o in options) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: o.key,
                    selected: selected == o.key,
                    onTap: () => _select(c, selected == o.key ? null : o.key),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: color,
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 58,
                  color: SwaramColors.onAmber.withAlpha(36),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SwaramColors.onAmber,
                      fontSize: 17,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: SwaramColors.onAmber.withAlpha(190),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SwaramColors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? SwaramColors.amber : SwaramColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? SwaramColors.onAmber : SwaramColors.text,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Track track;
  final Color color;
  final String genre;
  final String vibe;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _ResultTile({
    required this.track,
    required this.color,
    required this.genre,
    required this.vibe,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final tags = [if (genre.isNotEmpty) genre, if (vibe.isNotEmpty) vibe];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
              child: Icon(
                track.isVideo ? Icons.videocam_rounded : Icons.music_note,
                color: SwaramColors.onAmber,
                size: 24,
              ),
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
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final tag in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: SwaramColors.border),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: SwaramColors.textSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDownload,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: SwaramColors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.file_download_outlined,
                        color: SwaramColors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${track.points} pts',
                      style: const TextStyle(
                        color: SwaramColors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}