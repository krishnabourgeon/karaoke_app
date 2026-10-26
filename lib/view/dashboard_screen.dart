// import 'package:flutter/material.dart';
// import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';
// import 'package:karaoke_app/view/video_player_screen.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'library_store.dart';
// import 'song_detail_screen.dart';
// import 'upload_screen.dart';


// class DashboardScreen extends StatefulWidget {
//   final String userName;
//   final int? points;
//   final List<Track>? tracks;
//   final void Function(Track track)? onDownload;
//   final VoidCallback? onUpload;
//   final VoidCallback? onProfile;
//   final VoidCallback? onLibrary;

//   const DashboardScreen({
//     super.key,
//     this.userName = 'Arjun',
//     this.points,
//     this.tracks,
//     this.onDownload,
//     this.onUpload,
//     this.onProfile,
//     this.onLibrary,
//   });

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocus = FocusNode();
//   String _query = '';
//   String _language = 'All';

//   @override
//   void initState() {
//     super.initState();
//       Permission.notification.request();
//     }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _searchFocus.dispose();
//     super.dispose();
//   }

//   List<Track> get _allTracks => widget.tracks ?? LibraryStore.instance.tracks;

//   int get _points => widget.points ?? LibraryStore.instance.points;

//   List<String> get _languages {
//     final set = <String>{};
//     for (final t in _allTracks) {
//       set.add(t.language);
//     }
//     return ['All', ...set];
//   }

//   List<Track> get _filtered {
//     final q = _query.trim().toLowerCase();
//     return _allTracks.where((t) {
//       final matchesLanguage = _language == 'All' || t.language == _language;
//       final matchesQuery = q.isEmpty ||
//           t.title.toLowerCase().contains(q) ||
//           t.uploader.toLowerCase().contains(q);
//       return matchesLanguage && matchesQuery;
//     }).toList();
//   }

//   String get _greeting {
//     final h = DateTime.now().hour;
//     if (h < 12) return 'Good morning';
//     if (h < 17) return 'Good afternoon';
//     return 'Good evening';
//   }

//   Future<void> _handleDownload(Track track) async {
//     final result = await LibraryStore.instance.download(track);
//     if (!mounted) return;
//     switch (result) {
//       case DownloadResult.saved:
//         _snack('Saved "${track.title}" to your device.');
//       case DownloadResult.cancelled:
//         _snack('Download cancelled.');
//       case DownloadResult.notEnoughPoints:
//         _snack('Not enough points. Upload a karaoke to earn more.');
//       case DownloadResult.failed:
//         _snack('Could not save this track. Try again.');
//     }
//   }

//   void _openSong(List<Track> list, int index) {

//     final track = list[index];
//     if(track.isVideo){
//       Navigator.of(context).push(VideoPlayerScreen.route(track, onDownload: _handleDownload));
//       return;
//     }
//     final audioTrack = list.where((t)=> !t.isVideo).toList();
//     Navigator.of(context).push(
//       SongDetailScreen.route(
//         tracks: audioTrack,
//         index: audioTrack.indexWhere((t)=> t.id == track.id),
//         onDownload: _handleDownload,
//       ),
//     );
//   }

//   void _openUpload() {
//     Navigator.of(context).push(UploadScreen.route());
//   }

//   void _snack(String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           backgroundColor: SwaramColors.card,
//           behavior: SnackBarBehavior.floating,
//           content: Text(message, style: const TextStyle(color: SwaramColors.text)),
//         ),
//       );
//   }

//   void _openProfile() {
//     if (widget.onProfile != null) {
//       widget.onProfile!();
//     } else {
//       Navigator.of(context).pushNamed('/profile');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: LibraryStore.instance,
//       builder: (context, _) => _buildScaffold(context),
//     );
//   }

//   Widget _buildScaffold(BuildContext context) {
//     final tracks = _filtered;

//     return Scaffold(
//       backgroundColor: SwaramColors.bg,
//       resizeToAvoidBottomInset: false,
//       body: SafeArea(
//         bottom: false,
//         child: GestureDetector(
//           behavior: HitTestBehavior.translucent,
//           onTap: () => FocusScope.of(context).unfocus(),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                 child: _Header(
//                   greeting: _greeting,
//                   name: widget.userName,
//                   points: _points,
//                   onProfile: _openProfile,
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
//                 child: _SearchBar(
//                   controller: _searchController,
//                   focusNode: _searchFocus,
//                   onChanged: (v) => setState(() => _query = v),
//                   onClear: () {
//                     _searchController.clear();
//                     setState(() => _query = '');
//                   },
//                 ),
//               ),
//               const SizedBox(height: 14),
//               SizedBox(
//                 height: 40,
//                 child: ListView.separated(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   scrollDirection: Axis.horizontal,
//                   itemCount: _languages.length,
//                   separatorBuilder: (_, __) => const SizedBox(width: 8),
//                   itemBuilder: (context, i) {
//                     final lang = _languages[i];
//                     return _LanguageChip(
//                       label: lang,
//                       selected: lang == _language,
//                       onTap: () => setState(() => _language = lang),
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Karaoke library',
//                       style: TextStyle(
//                         color: SwaramColors.text,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     Text(
//                       '${tracks.length} ${tracks.length == 1 ? 'track' : 'tracks'}',
//                       style: const TextStyle(color: SwaramColors.muted, fontSize: 13),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: tracks.isEmpty
//                     ? const _EmptyState()
//                     : ListView.separated(
//                         padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
//                         itemCount: tracks.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 10),
//                         itemBuilder: (context, i) => GestureDetector(
//                           behavior: HitTestBehavior.opaque,
//                           onTap: () => _openSong(tracks, i),
//                           child: _TrackTile(
//                             track: tracks[i],
//                             color: trackColor(tracks[i]),
//                             onDownload: () => _handleDownload(tracks[i]),
//                           ),
//                         ),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: SwaramBottomNav(
//         current: SwaramTab.home,
//         // onSearch: () => _searchFocus.requestFocus(),
//         onSearch: () => Navigator.of(context).pushNamed('/search'),
//         onUpload: widget.onUpload ?? _openUpload,
//         onLibrary: widget.onLibrary ??
//             () => Navigator.of(context).pushNamed('/library'),
//         onProfile: _openProfile,
//       ),
//     );
//   }
// }

// class _Header extends StatelessWidget {
//   final String greeting;
//   final String name;
//   final int points;
//   final VoidCallback? onProfile;

//   const _Header({
//     required this.greeting,
//     required this.name,
//     required this.points,
//     this.onProfile,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 greeting,
//                 style: const TextStyle(color: SwaramColors.muted, fontSize: 14),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 name,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   color: SwaramColors.text,
//                   fontSize: 26,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         GestureDetector(
//           onTap: onProfile,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
//             decoration: BoxDecoration(
//               color: SwaramColors.card,
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 22,
//                   height: 22,
//                   decoration: const BoxDecoration(
//                     color: SwaramColors.amber,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(Icons.music_note, size: 14, color: SwaramColors.onAmber),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   '$points pts',
//                   style: const TextStyle(
//                     color: SwaramColors.amber,
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _SearchBar extends StatelessWidget {
//   final TextEditingController controller;
//   final FocusNode focusNode;
//   final ValueChanged<String> onChanged;
//   final VoidCallback onClear;

//   const _SearchBar({
//     required this.controller,
//     required this.focusNode,
//     required this.onChanged,
//     required this.onClear,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 52,
//       decoration: BoxDecoration(
//         color: SwaramColors.card,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: SwaramColors.border),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: Row(
//         children: [
//           const Icon(Icons.search, color: SwaramColors.muted, size: 22),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextField(
//               controller: controller,
//               focusNode: focusNode,
//               onChanged: onChanged,
//               textInputAction: TextInputAction.search,
//               cursorColor: SwaramColors.amber,
//               style: const TextStyle(color: SwaramColors.text, fontSize: 15),
//               decoration: const InputDecoration(
//                 hintText: 'Search songs or artists',
//                 hintStyle: TextStyle(color: SwaramColors.muted, fontSize: 15),
//                 border: InputBorder.none,
//                 isDense: true,
//               ),
//             ),
//           ),
//           if (controller.text.isNotEmpty)
//             GestureDetector(
//               onTap: onClear,
//               child: const Icon(Icons.close, color: SwaramColors.muted, size: 20),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _LanguageChip extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   const _LanguageChip({
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 160),
//         padding: const EdgeInsets.symmetric(horizontal: 18),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: selected ? SwaramColors.amber : Colors.transparent,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(color: selected ? SwaramColors.amber : SwaramColors.border),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: selected ? SwaramColors.onAmber : SwaramColors.text,
//             fontSize: 14,
//             fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _TrackTile extends StatelessWidget {
//   final Track track;
//   final Color color;
//   final VoidCallback onDownload;

//   const _TrackTile({
//     required this.track,
//     required this.color,
//     required this.onDownload,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: SwaramColors.card,
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: color,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(Icons.music_note, color: SwaramColors.onAmber, size: 24),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   track.title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: SwaramColors.text,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   '${track.language} · ${track.duration} · ${track.uploader}',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(color: SwaramColors.muted, fontSize: 12.5),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           GestureDetector(
//             onTap: onDownload,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(color: SwaramColors.amber),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.file_download_outlined,
//                       color: SwaramColors.amber, size: 18),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   const _EmptyState();

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.only(bottom: 80),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.search_off, color: SwaramColors.muted, size: 40),
//             SizedBox(height: 12),
//             Text(
//               'No tracks found',
//               style: TextStyle(
//                 color: SwaramColors.text,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             SizedBox(height: 4),
//             Text(
//               'Try another name or language.',
//               style: TextStyle(color: SwaramColors.muted, fontSize: 13),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }












import 'package:flutter/material.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/video_player_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'library_store.dart';
import 'package:karaoke_app/view/common_widgets/record_launcher.dart';
import 'song_detail_screen.dart';
import 'upload_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final int? points;
  final List<Track>? tracks;
  final void Function(Track track)? onDownload;
  final VoidCallback? onUpload;
  final VoidCallback? onRecord;
  final VoidCallback? onProfile;
  final VoidCallback? onLibrary;

  const DashboardScreen({
    super.key,
    this.userName = 'Arjun',
    this.points,
    this.tracks,
    this.onDownload,
    this.onUpload,
    this.onRecord,
    this.onProfile,
    this.onLibrary,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  String _language = 'All';

  @override
  void initState() {
    super.initState();
    Permission.notification.request();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Track> get _allTracks => widget.tracks ?? LibraryStore.instance.tracks;

  int get _points => widget.points ?? LibraryStore.instance.points;

  List<String> get _languages {
    final set = <String>{};
    for (final t in _allTracks) {
      set.add(t.language);
    }
    return ['All', ...set];
  }

  List<Track> get _filtered {
    final q = _query.trim().toLowerCase();
    return _allTracks.where((t) {
      final matchesLanguage = _language == 'All' || t.language == _language;
      final matchesQuery = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.uploader.toLowerCase().contains(q);
      return matchesLanguage && matchesQuery;
    }).toList();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
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

  void _openSong(List<Track> list, int index) {
    final track = list[index];
    if (track.isVideo) {
      Navigator.of(context)
          .push(VideoPlayerScreen.route(track, onDownload: _handleDownload));
      return;
    }
    final audioTrack = list.where((t) => !t.isVideo).toList();
    Navigator.of(context).push(
      SongDetailScreen.route(
        tracks: audioTrack,
        index: audioTrack.indexWhere((t) => t.id == track.id),
        onDownload: _handleDownload,
      ),
    );
  }

  void _openUpload() {
    Navigator.of(context).push(UploadScreen.route());
  }

  void _openRecord() => openRecordPicker(context);

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

  void _openProfile() {
    if (widget.onProfile != null) {
      widget.onProfile!();
    } else {
      Navigator.of(context).pushNamed('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LibraryStore.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final tracks = _filtered;

    return Scaffold(
      backgroundColor: SwaramColors.bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _Header(
                  greeting: _greeting,
                  name: widget.userName,
                  points: _points,
                  onProfile: _openProfile,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final lang = _languages[i];
                    return _LanguageChip(
                      label: lang,
                      selected: lang == _language,
                      onTap: () => setState(() => _language = lang),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Karaoke library',
                      style: TextStyle(
                        color: SwaramColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${tracks.length} ${tracks.length == 1 ? 'track' : 'tracks'}',
                          style: const TextStyle(
                              color: SwaramColors.muted, fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        // Record: pick any song or uploaded video to sing.
                        GestureDetector(
                          onTap: widget.onRecord ?? _openRecord,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: SwaramColors.teal,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic_rounded,
                                    color: SwaramColors.onAmber, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Record',
                                  style: TextStyle(
                                    color: SwaramColors.onAmber,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tracks.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        itemCount: tracks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openSong(tracks, i),
                          child: _TrackTile(
                            track: tracks[i],
                            color: trackColor(tracks[i]),
                            onDownload: () => _handleDownload(tracks[i]),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SwaramBottomNav(
        current: SwaramTab.home,
        onSearch: () => Navigator.of(context).pushNamed('/search'),
        // The + button opens a menu: Upload and Record.
        onUpload: widget.onUpload ?? _openUpload,
        onRecord: widget.onRecord ?? _openRecord,
        onLibrary: widget.onLibrary ??
            () => Navigator.of(context).pushNamed('/library'),
        onProfile: _openProfile,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String name;
  final int points;
  final VoidCallback? onProfile;

  const _Header({
    required this.greeting,
    required this.name,
    required this.points,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(color: SwaramColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SwaramColors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: SwaramColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: SwaramColors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.music_note,
                      size: 14, color: SwaramColors.onAmber),
                ),
                const SizedBox(width: 8),
                Text(
                  '$points pts',
                  style: const TextStyle(
                    color: SwaramColors.amber,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: SwaramColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SwaramColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: SwaramColors.muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: SwaramColors.amber,
              style: const TextStyle(color: SwaramColors.text, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Search songs or artists',
                hintStyle: TextStyle(color: SwaramColors.muted, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child:
                  const Icon(Icons.close, color: SwaramColors.muted, size: 20),
            ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
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
              color: selected ? SwaramColors.amber : SwaramColors.border),
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

class _TrackTile extends StatelessWidget {
  final Track track;
  final Color color;
  final VoidCallback onDownload;

  const _TrackTile({
    required this.track,
    required this.color,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      color: SwaramColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDownload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: SwaramColors.amber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.file_download_outlined,
                      color: SwaramColors.amber, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sing this song: opens the record screen with this track.
          GestureDetector(
            onTap: () => openRecordFor(context, track),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: SwaramColors.teal),
              ),
              child: const Icon(Icons.mic_rounded,
                  color: SwaramColors.teal, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: SwaramColors.muted, size: 40),
            SizedBox(height: 12),
            Text(
              'No tracks found',
              style: TextStyle(
                color: SwaramColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another name or language.',
              style: TextStyle(color: SwaramColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}