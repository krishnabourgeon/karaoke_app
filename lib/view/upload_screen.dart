// // import 'package:file_picker/file_picker.dart';
// // import 'package:flutter/material.dart';
// // import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
// // import 'library_store.dart';

// // class UploadScreen extends StatefulWidget {
// //   const UploadScreen({super.key});

// //   /// Slides up from the bottom, like the song screen.
// //   static Route<void> route() {
// //     return PageRouteBuilder<void>(
// //       transitionDuration: const Duration(milliseconds: 400),
// //       reverseTransitionDuration: const Duration(milliseconds: 300),
// //       pageBuilder: (_, __, ___) => const UploadScreen(),
// //       transitionsBuilder: (_, animation, __, child) {
// //         final curved = CurvedAnimation(
// //           parent: animation,
// //           curve: Curves.easeOutCubic,
// //           reverseCurve: Curves.easeInCubic,
// //         );
// //         return SlideTransition(
// //           position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
// //               .animate(curved),
// //           child: child,
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   State<UploadScreen> createState() => _UploadScreenState();
// // }

// // class _UploadScreenState extends State<UploadScreen>
// //     with SingleTickerProviderStateMixin {
// //   static const _languages = ['Malayalam', 'Hindi', 'Tamil', 'Telugu', 'Other'];

// //   late final AnimationController _enter = AnimationController(
// //     vsync: this,
// //     duration: const Duration(milliseconds: 1200),
// //   )..forward();

// //   final TextEditingController _titleController = TextEditingController();
// //   PlatformFile? _picked;
// //   String _language = _languages.first;
// //   bool _saving = false;
// //   String? _titleError;
// //   String? _fileError;
// //   bool _isVideo = false;

// //   @override
// //   void dispose() {
// //     _enter.dispose();
// //     _titleController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _pickFile() async {
// //     //final file = await FilePicker.pickFile(type: FileType.audio);
// //     final file = await FilePicker.pickFile(
// //       type: FileType.custom,
// //       allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'mp4', 'mkv', 'mov', 'webm'],
// //     );
// //     if (file == null) return;

// //     if (file.path == null) {
// //       _toast('Could not read that file. Try another one.');
// //       return;
// //     }

// //     setState(() {
// //       _picked = file;
// //       final ext = file.name.split('.').last.toLowerCase();
// //       _isVideo = ['mp4', 'mkv', 'mov', 'webm'].contains(ext);
// //       _fileError = null;
// //       if (_titleController.text.trim().isEmpty) {
// //         final dot = file.name.lastIndexOf('.');
// //         _titleController.text = dot > 0 ? file.name.substring(0, dot) : file.name;
// //         _titleError = null;
// //       }
// //     });
// //   }

// //   Future<void> _upload() async {
// //     FocusScope.of(context).unfocus();

// //     setState(() {
// //       _fileError = _picked == null ? 'Choose an audio file first' : null;
// //       _titleError =
// //           _titleController.text.trim().isEmpty ? 'Enter a title' : null;
// //     });
// //     if (_fileError != null || _titleError != null) return;

// //     setState(() => _saving = true);
// //     try {
// //       await LibraryStore.instance.addUpload(
// //         sourcePath: _picked!.path!,
// //         title: _titleController.text,
// //         language: _language,
// //         isVideo: _isVideo
// //       );
// //       if (!mounted) return;
// //       final messenger = ScaffoldMessenger.of(context);
// //       Navigator.of(context).pop();
// //       messenger
// //         ..hideCurrentSnackBar()
// //         ..showSnackBar(
// //           SnackBar(
// //             backgroundColor: SwaramColors.card,
// //             behavior: SnackBarBehavior.floating,
// //             content: Text(
// //               'Uploaded. +${LibraryStore.uploadReward} pts added.',
// //               style: const TextStyle(color: SwaramColors.text),
// //             ),
// //           ),
// //         );
// //     } catch (_) {
// //       if (!mounted) return;
// //       setState(() => _saving = false);
// //       _toast('Upload failed. Please try again.');
// //     }
// //   }

// //   void _toast(String message) {
// //     ScaffoldMessenger.of(context)
// //       ..hideCurrentSnackBar()
// //       ..showSnackBar(
// //         SnackBar(
// //           backgroundColor: SwaramColors.card,
// //           behavior: SnackBarBehavior.floating,
// //           content:
// //               Text(message, style: const TextStyle(color: SwaramColors.text)),
// //         ),
// //       );
// //   }

// //   String _sizeText(int? bytes) {
// //     if (bytes == null || bytes <= 0) return 'Audio file';
// //     final mb = bytes / (1024 * 1024);
// //     return mb >= 1
// //         ? '${mb.toStringAsFixed(1)} MB'
// //         : '${(bytes / 1024).round()} KB';
// //   }

// //   OutlineInputBorder _border(Color color, [double width = 1]) {
// //     return OutlineInputBorder(
// //       borderRadius: BorderRadius.circular(18),
// //       borderSide: BorderSide(color: color, width: width),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final picked = _picked;

// //     return Scaffold(
// //       backgroundColor: SwaramColors.bg,
// //       body: SafeArea(
// //         child: GestureDetector(
// //           behavior: HitTestBehavior.translucent,
// //           onTap: () => FocusScope.of(context).unfocus(),
// //           child: SingleChildScrollView(
// //             padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Row(
// //                   children: [
// //                     IconButton(
// //                       onPressed: () => Navigator.of(context).pop(),
// //                       icon: const Icon(Icons.keyboard_arrow_down_rounded,
// //                           color: SwaramColors.text, size: 34),
// //                     ),
// //                     const Text(
// //                       'Upload karaoke',
// //                       style: TextStyle(
// //                         color: SwaramColors.text,
// //                         fontSize: 24,
// //                         fontWeight: FontWeight.w800,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 12),
// //                 FadeSlide(
// //                   controller: _enter,
// //                   begin: 0.0,
// //                   end: 0.4,
// //                   child: Container(
// //                     padding: const EdgeInsets.all(14),
// //                     decoration: BoxDecoration(
// //                       color: SwaramColors.card,
// //                       borderRadius: BorderRadius.circular(20),
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         Container(
// //                           width: 44,
// //                           height: 44,
// //                           decoration: BoxDecoration(
// //                             color: SwaramColors.pink,
// //                             borderRadius: BorderRadius.circular(14),
// //                           ),
// //                           child: const Icon(Icons.file_upload_outlined,
// //                               color: SwaramColors.onAmber),
// //                         ),
// //                         const SizedBox(width: 14),
// //                         const Expanded(
// //                           child: Text(
// //                             'Every upload earns +20 pts.',
// //                             style: TextStyle(
// //                               color: SwaramColors.text,
// //                               fontSize: 15,
// //                               fontWeight: FontWeight.w700,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 FadeSlide(
// //                   controller: _enter,
// //                   begin: 0.15,
// //                   end: 0.55,
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       PressScale(
// //                         onTap: _pickFile,
// //                         child: Container(
// //                           width: double.infinity,
// //                           padding: const EdgeInsets.symmetric(
// //                               vertical: 26, horizontal: 16),
// //                           decoration: BoxDecoration(
// //                             color: SwaramColors.card,
// //                             borderRadius: BorderRadius.circular(22),
// //                             border: Border.all(
// //                               color: _fileError != null
// //                                   ? SwaramColors.pink
// //                                   : (picked != null
// //                                       ? SwaramColors.amber
// //                                       : SwaramColors.border),
// //                               width: 1.5,
// //                             ),
// //                           ),
// //                           child: Column(
// //                             children: [
// //                               Icon(
// //                                 picked != null
// //                                     ? Icons.audio_file_outlined
// //                                     : Icons.upload_file_outlined,
// //                                 color: SwaramColors.amber,
// //                                 size: 36,
// //                               ),
// //                               const SizedBox(height: 10),
// //                               Text(
// //                                 picked?.name ?? 'Choose audio file',
// //                                 maxLines: 1,
// //                                 overflow: TextOverflow.ellipsis,
// //                                 textAlign: TextAlign.center,
// //                                 style: const TextStyle(
// //                                   color: SwaramColors.text,
// //                                   fontSize: 16,
// //                                   fontWeight: FontWeight.w700,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 4),
// //                               Text(
// //                                 picked != null
// //                                     ? '${_sizeText(picked.lengthSync())} · tap to change'
// //                                     : 'MP3, M4A, WAV and more',
// //                                 style: const TextStyle(
// //                                   color: SwaramColors.muted,
// //                                   fontSize: 13,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                       if (_fileError != null)
// //                         Padding(
// //                           padding: const EdgeInsets.only(top: 6, left: 4),
// //                           child: Text(
// //                             _fileError!,
// //                             style: const TextStyle(
// //                                 color: SwaramColors.pink, fontSize: 12.5),
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 FadeSlide(
// //                   controller: _enter,
// //                   begin: 0.3,
// //                   end: 0.7,
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const _Label('Title'),
// //                       TextField(
// //                         controller: _titleController,
// //                         textInputAction: TextInputAction.done,
// //                         cursorColor: SwaramColors.amber,
// //                         onChanged: (_) {
// //                           if (_titleError != null) {
// //                             setState(() => _titleError = null);
// //                           }
// //                         },
// //                         style: const TextStyle(
// //                             color: SwaramColors.text, fontSize: 16),
// //                         decoration: InputDecoration(
// //                           hintText: 'Song name',
// //                           hintStyle: TextStyle(
// //                               color: SwaramColors.muted.withAlpha(150)),
// //                           errorText: _titleError,
// //                           errorStyle: const TextStyle(
// //                               color: SwaramColors.pink, fontSize: 12.5),
// //                           filled: true,
// //                           fillColor: SwaramColors.card,
// //                           contentPadding: const EdgeInsets.symmetric(
// //                               horizontal: 20, vertical: 18),
// //                           border: _border(SwaramColors.border),
// //                           enabledBorder: _border(SwaramColors.border),
// //                           focusedBorder: _border(SwaramColors.amber, 1.5),
// //                           errorBorder: _border(SwaramColors.pink),
// //                           focusedErrorBorder: _border(SwaramColors.pink, 1.5),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 FadeSlide(
// //                   controller: _enter,
// //                   begin: 0.4,
// //                   end: 0.8,
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const _Label('Language'),
// //                       Wrap(
// //                         spacing: 8,
// //                         runSpacing: 8,
// //                         children: [
// //                           for (final lang in _languages)
// //                             GestureDetector(
// //                               onTap: () => setState(() => _language = lang),
// //                               child: AnimatedContainer(
// //                                 duration: const Duration(milliseconds: 160),
// //                                 padding: const EdgeInsets.symmetric(
// //                                     horizontal: 18, vertical: 10),
// //                                 decoration: BoxDecoration(
// //                                   color: lang == _language
// //                                       ? SwaramColors.amber
// //                                       : Colors.transparent,
// //                                   borderRadius: BorderRadius.circular(24),
// //                                   border: Border.all(
// //                                     color: lang == _language
// //                                         ? SwaramColors.amber
// //                                         : SwaramColors.border,
// //                                   ),
// //                                 ),
// //                                 child: Text(
// //                                   lang,
// //                                   style: TextStyle(
// //                                     color: lang == _language
// //                                         ? SwaramColors.onAmber
// //                                         : SwaramColors.text,
// //                                     fontSize: 14,
// //                                     fontWeight: FontWeight.w700,
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 30),
// //                 FadeSlide(
// //                   controller: _enter,
// //                   begin: 0.55,
// //                   end: 1.0,
// //                   child: PressScale(
// //                     onTap: _saving ? null : _upload,
// //                     child: Container(
// //                       height: 58,
// //                       alignment: Alignment.center,
// //                       decoration: BoxDecoration(
// //                         color: SwaramColors.amber,
// //                         borderRadius: BorderRadius.circular(30),
// //                       ),
// //                       child: AnimatedSwitcher(
// //                         duration: const Duration(milliseconds: 200),
// //                         child: _saving
// //                             ? const SizedBox(
// //                                 key: ValueKey('saving'),
// //                                 width: 24,
// //                                 height: 24,
// //                                 child: CircularProgressIndicator(
// //                                   strokeWidth: 3,
// //                                   color: SwaramColors.onAmber,
// //                                 ),
// //                               )
// //                             : const Text(
// //                                 'Upload',
// //                                 key: ValueKey('label'),
// //                                 style: TextStyle(
// //                                   color: SwaramColors.onAmber,
// //                                   fontSize: 18,
// //                                   fontWeight: FontWeight.w800,
// //                                 ),
// //                               ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _Label extends StatelessWidget {
// //   final String text;
// //   const _Label(this.text);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 8),
// //       child: Text(
// //         text,
// //         style: const TextStyle(
// //           color: SwaramColors.textSoft,
// //           fontSize: 14,
// //           fontWeight: FontWeight.w700,
// //         ),
// //       ),
// //     );
// //   }
// // }




// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
// import 'library_store.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   /// Slides up from the bottom, like the song screen.
//   static Route<void> route() {
//     return PageRouteBuilder<void>(
//       transitionDuration: const Duration(milliseconds: 400),
//       reverseTransitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (_, __, ___) => const UploadScreen(),
//       transitionsBuilder: (_, animation, __, child) {
//         final curved = CurvedAnimation(
//           parent: animation,
//           curve: Curves.easeOutCubic,
//           reverseCurve: Curves.easeInCubic,
//         );
//         return SlideTransition(
//           position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
//               .animate(curved),
//           child: child,
//         );
//       },
//     );
//   }

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen>
//     with SingleTickerProviderStateMixin {
//   static const _languages = ['Malayalam', 'Hindi', 'Tamil', 'Telugu', 'Other'];

//   // Edit these lists to change the options shown on the screen.
//   static const _genres = [
//     'Romantic',
//     'Feel good',
//     'Melody',
//     'Sad',
//     'Devotional',
//     'Party',
//     'Folk',
//     'Classical',
//   ];
//   static const _vibes = [
//     "80's vibe",
//     "90's vibe",
//     "2000's vibe",
//     'Retro',
//     'Modern',
//     'Evergreen',
//   ];

//   late final AnimationController _enter = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 1400),
//   )..forward();

//   final TextEditingController _titleController = TextEditingController();
//   PlatformFile? _picked;
//   String _language = _languages.first;
//   String _genre = _genres.first; // pick one, tap again to clear
//   String _vibe = _vibes.first; // pick one, tap again to clear
//   bool _saving = false;
//   String? _titleError;
//   String? _fileError;
//   bool _isVideo = false;

//   @override
//   void dispose() {
//     _enter.dispose();
//     _titleController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFile() async {
//     //final file = await FilePicker.pickFile(type: FileType.audio);
//     final file = await FilePicker.pickFile(
//       type: FileType.custom,
//       allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'mp4', 'mkv', 'mov', 'webm'],
//     );
//     if (file == null) return;

//     if (file.path == null) {
//       _toast('Could not read that file. Try another one.');
//       return;
//     }

//     setState(() {
//       _picked = file;
//       final ext = file.name.split('.').last.toLowerCase();
//       _isVideo = ['mp4', 'mkv', 'mov', 'webm'].contains(ext);
//       _fileError = null;
//       if (_titleController.text.trim().isEmpty) {
//         final dot = file.name.lastIndexOf('.');
//         _titleController.text = dot > 0 ? file.name.substring(0, dot) : file.name;
//         _titleError = null;
//       }
//     });
//   }

//   Future<void> _upload() async {
//     FocusScope.of(context).unfocus();

//     setState(() {
//       _fileError = _picked == null ? 'Choose an audio file first' : null;
//       _titleError =
//           _titleController.text.trim().isEmpty ? 'Enter a title' : null;
//     });
//     if (_fileError != null || _titleError != null) return;

//     setState(() => _saving = true);
//     try {
//       await LibraryStore.instance.addUpload(
//         sourcePath: _picked!.path!,
//         title: _titleController.text,
//         language: _language,
//         genre: _genre,
//         vibe: _vibe,
//         isVideo: _isVideo,
//       );
//       if (!mounted) return;
//       final messenger = ScaffoldMessenger.of(context);
//       Navigator.of(context).pop();
//       messenger
//         ..hideCurrentSnackBar()
//         ..showSnackBar(
//           SnackBar(
//             backgroundColor: SwaramColors.card,
//             behavior: SnackBarBehavior.floating,
//             content: Text(
//               'Uploaded. +${LibraryStore.uploadReward} pts added.',
//               style: const TextStyle(color: SwaramColors.text),
//             ),
//           ),
//         );
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _saving = false);
//       _toast('Upload failed. Please try again.');
//     }
//   }

//   void _toast(String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           backgroundColor: SwaramColors.card,
//           behavior: SnackBarBehavior.floating,
//           content:
//               Text(message, style: const TextStyle(color: SwaramColors.text)),
//         ),
//       );
//   }

//   String _sizeText(int? bytes) {
//     if (bytes == null || bytes <= 0) return 'Audio file';
//     final mb = bytes / (1024 * 1024);
//     return mb >= 1
//         ? '${mb.toStringAsFixed(1)} MB'
//         : '${(bytes / 1024).round()} KB';
//   }

//   OutlineInputBorder _border(Color color, [double width = 1]) {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(18),
//       borderSide: BorderSide(color: color, width: width),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final picked = _picked;

//     return Scaffold(
//       backgroundColor: SwaramColors.bg,
//       body: SafeArea(
//         child: GestureDetector(
//           behavior: HitTestBehavior.translucent,
//           onTap: () => FocusScope.of(context).unfocus(),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     IconButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       icon: const Icon(Icons.keyboard_arrow_down_rounded,
//                           color: SwaramColors.text, size: 34),
//                     ),
//                     const Text(
//                       'Upload karaoke',
//                       style: TextStyle(
//                         color: SwaramColors.text,
//                         fontSize: 24,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 FadeSlide(
//                   controller: _enter,
//                   begin: 0.0,
//                   end: 0.4,
//                   child: Container(
//                     padding: const EdgeInsets.all(14),
//                     decoration: BoxDecoration(
//                       color: SwaramColors.card,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 44,
//                           height: 44,
//                           decoration: BoxDecoration(
//                             color: SwaramColors.pink,
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: const Icon(Icons.file_upload_outlined,
//                               color: SwaramColors.onAmber),
//                         ),
//                         const SizedBox(width: 14),
//                         const Expanded(
//                           child: Text(
//                             'Every upload earns +20 pts.',
//                             style: TextStyle(
//                               color: SwaramColors.text,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 FadeSlide(
//                   controller: _enter,
//                   begin: 0.1,
//                   end: 0.5,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       PressScale(
//                         onTap: _pickFile,
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(
//                               vertical: 26, horizontal: 16),
//                           decoration: BoxDecoration(
//                             color: SwaramColors.card,
//                             borderRadius: BorderRadius.circular(22),
//                             border: Border.all(
//                               color: _fileError != null
//                                   ? SwaramColors.pink
//                                   : (picked != null
//                                       ? SwaramColors.amber
//                                       : SwaramColors.border),
//                               width: 1.5,
//                             ),
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(
//                                 picked != null
//                                     ? Icons.audio_file_outlined
//                                     : Icons.upload_file_outlined,
//                                 color: SwaramColors.amber,
//                                 size: 36,
//                               ),
//                               const SizedBox(height: 10),
//                               Text(
//                                 picked?.name ?? 'Choose audio file',
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   color: SwaramColors.text,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 picked != null
//                                     ? '${_sizeText(picked.lengthSync())} · tap to change'
//                                     : 'MP3, M4A, WAV and more',
//                                 style: const TextStyle(
//                                   color: SwaramColors.muted,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       if (_fileError != null)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 6, left: 4),
//                           child: Text(
//                             _fileError!,
//                             style: const TextStyle(
//                                 color: SwaramColors.pink, fontSize: 12.5),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 FadeSlide(
//                   controller: _enter,
//                   begin: 0.2,
//                   end: 0.6,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const _Label('Title'),
//                       TextField(
//                         controller: _titleController,
//                         textInputAction: TextInputAction.done,
//                         cursorColor: SwaramColors.amber,
//                         onChanged: (_) {
//                           if (_titleError != null) {
//                             setState(() => _titleError = null);
//                           }
//                         },
//                         style: const TextStyle(
//                             color: SwaramColors.text, fontSize: 16),
//                         decoration: InputDecoration(
//                           hintText: 'Song name',
//                           hintStyle: TextStyle(
//                               color: SwaramColors.muted.withAlpha(150)),
//                           errorText: _titleError,
//                           errorStyle: const TextStyle(
//                               color: SwaramColors.pink, fontSize: 12.5),
//                           filled: true,
//                           fillColor: SwaramColors.card,
//                           contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 18),
//                           border: _border(SwaramColors.border),
//                           enabledBorder: _border(SwaramColors.border),
//                           focusedBorder: _border(SwaramColors.amber, 1.5),
//                           errorBorder: _border(SwaramColors.pink),
//                           focusedErrorBorder: _border(SwaramColors.pink, 1.5),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 FadeSlide(
//                   controller: _enter,
//                   begin: 0.3,
//                   end: 0.7,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const _Label('Language'),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: [
//                           for (final lang in _languages)
//                             _OptionChip(
//                               label: lang,
//                               selected: lang == _language,
//                               onTap: () => setState(() => _language = lang),
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 FadeSlide(
//                   controller: _enter,
//                   begin: 0.4,
//                   end: 0.8,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const _Label('Genre'),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: [
//                           for (final genre in _genres)
//                             _OptionChip(
//                               label: genre,
//                               selected: genre == _genre,
//                               onTap: () => setState(
//                                   () => _genre = genre),
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 FadeSlide(
//                   controller: _enter,
//                   begin: 0.5,
//                   end: 0.9,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const _Label('Vibe'),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: [
//                           for (final vibe in _vibes)
//                             _OptionChip(
//                               label: vibe,
//                               selected: vibe == _vibe,
//                               onTap: () => setState(
//                                   () => _vibe = vibe),
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 FadeSlide(
//                   controller: _enter,
//                   begin: 0.6,
//                   end: 1.0,
//                   child: PressScale(
//                     onTap: _saving ? null : _upload,
//                     child: Container(
//                       height: 58,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: SwaramColors.amber,
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: AnimatedSwitcher(
//                         duration: const Duration(milliseconds: 200),
//                         child: _saving
//                             ? const SizedBox(
//                                 key: ValueKey('saving'),
//                                 width: 24,
//                                 height: 24,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 3,
//                                   color: SwaramColors.onAmber,
//                                 ),
//                               )
//                             : const Text(
//                                 'Upload',
//                                 key: ValueKey('label'),
//                                 style: TextStyle(
//                                   color: SwaramColors.onAmber,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w800,
//                                 ),
//                               ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Rounded chip used for language, genre and vibe.
// class _OptionChip extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   const _OptionChip({
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
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? SwaramColors.amber : Colors.transparent,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//             color: selected ? SwaramColors.amber : SwaramColors.border,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: selected ? SwaramColors.onAmber : SwaramColors.text,
//             fontSize: 14,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _Label extends StatelessWidget {
//   final String text;
//   final String? hint;
//   const _Label(this.text, {this.hint});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Text(
//             text,
//             style: const TextStyle(
//               color: SwaramColors.textSoft,
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           if (hint != null) ...[
//             const SizedBox(width: 8),
//             Text(
//               hint!,
//               style: const TextStyle(
//                 color: SwaramColors.muted,
//                 fontSize: 12.5,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }




import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'library_store.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  /// Slides up from the bottom, like the song screen.
  static Route<void> route() {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const UploadScreen(),
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
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  static const _languages = ['Malayalam', 'Hindi', 'Tamil', 'Telugu', 'Other'];

  // Edit these lists to change the options shown on the screen.
  static const _genres = [
    'Romantic',
    'Feel good',
    'Melody',
    'Sad',
    'Devotional',
    'Party',
    'Folk',
    'Classical',
  ];
  static const _vibes = [
    "80's vibe",
    "90's vibe",
    "2000's vibe",
    'Retro',
    'Modern',
    'Evergreen',
  ];

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  final TextEditingController _titleController = TextEditingController();
  PlatformFile? _picked;
  String _language = _languages.first;
  String? _genre; // pick one, tap again to clear
  String? _vibe; // pick one, tap again to clear
  bool _saving = false;
  String? _titleError;
  String? _fileError;
  bool _isVideo = false;

  @override
  void dispose() {
    _enter.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    //final file = await FilePicker.pickFile(type: FileType.audio);
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'mp4', 'mkv', 'mov', 'webm'],
    );
    if (file == null) return;

    if (file.path == null) {
      _toast('Could not read that file. Try another one.');
      return;
    }

    setState(() {
      _picked = file;
      final ext = file.name.split('.').last.toLowerCase();
      _isVideo = ['mp4', 'mkv', 'mov', 'webm'].contains(ext);
      _fileError = null;
      if (_titleController.text.trim().isEmpty) {
        final dot = file.name.lastIndexOf('.');
        _titleController.text = dot > 0 ? file.name.substring(0, dot) : file.name;
        _titleError = null;
      }
    });
  }

  Future<void> _upload() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _fileError = _picked == null ? 'Choose an audio file first' : null;
      _titleError =
          _titleController.text.trim().isEmpty ? 'Enter a title' : null;
    });
    if (_fileError != null || _titleError != null) return;

    setState(() => _saving = true);
    try {
      await LibraryStore.instance.addUpload(
        sourcePath: _picked!.path!,
        title: _titleController.text,
        language: _language,
        genre: _genre ?? '',
        vibe: _vibe ?? '',
        isVideo: _isVideo,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: SwaramColors.card,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Uploaded. +${LibraryStore.uploadReward} pts added.',
              style: const TextStyle(color: SwaramColors.text),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Upload failed. Please try again.');
    }
  }

  void _toast(String message) {
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

  String _sizeText(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Audio file';
    final mb = bytes / (1024 * 1024);
    return mb >= 1
        ? '${mb.toStringAsFixed(1)} MB'
        : '${(bytes / 1024).round()} KB';
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;

    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: SwaramColors.text, size: 34),
                    ),
                    const Text(
                      'Upload karaoke',
                      style: TextStyle(
                        color: SwaramColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FadeSlide(
                  controller: _enter,
                  begin: 0.0,
                  end: 0.4,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SwaramColors.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SwaramColors.pink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.file_upload_outlined,
                              color: SwaramColors.onAmber),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Every upload earns +20 pts.',
                            style: TextStyle(
                              color: SwaramColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlide(
                  controller: _enter,
                  begin: 0.1,
                  end: 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PressScale(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 26, horizontal: 16),
                          decoration: BoxDecoration(
                            color: SwaramColors.card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _fileError != null
                                  ? SwaramColors.pink
                                  : (picked != null
                                      ? SwaramColors.amber
                                      : SwaramColors.border),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                picked != null
                                    ? Icons.audio_file_outlined
                                    : Icons.upload_file_outlined,
                                color: SwaramColors.amber,
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                picked?.name ?? 'Choose audio file',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: SwaramColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                picked != null
                                    ? '${_sizeText(picked.lengthSync())} · tap to change'
                                    : 'MP3, M4A, WAV and more',
                                style: const TextStyle(
                                  color: SwaramColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_fileError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            _fileError!,
                            style: const TextStyle(
                                color: SwaramColors.pink, fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlide(
                  controller: _enter,
                  begin: 0.2,
                  end: 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Title'),
                      TextField(
                        controller: _titleController,
                        textInputAction: TextInputAction.done,
                        cursorColor: SwaramColors.amber,
                        onChanged: (_) {
                          if (_titleError != null) {
                            setState(() => _titleError = null);
                          }
                        },
                        style: const TextStyle(
                            color: SwaramColors.text, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Song name',
                          hintStyle: TextStyle(
                              color: SwaramColors.muted.withAlpha(150)),
                          errorText: _titleError,
                          errorStyle: const TextStyle(
                              color: SwaramColors.pink, fontSize: 12.5),
                          filled: true,
                          fillColor: SwaramColors.card,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: _border(SwaramColors.border),
                          enabledBorder: _border(SwaramColors.border),
                          focusedBorder: _border(SwaramColors.amber, 1.5),
                          errorBorder: _border(SwaramColors.pink),
                          focusedErrorBorder: _border(SwaramColors.pink, 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlide(
                  controller: _enter,
                  begin: 0.3,
                  end: 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Language'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final lang in _languages)
                            _OptionChip(
                              label: lang,
                              selected: lang == _language,
                              onTap: () => setState(() => _language = lang),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlide(
                  controller: _enter,
                  begin: 0.4,
                  end: 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Genre', hint: 'Pick one'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final genre in _genres)
                            _OptionChip(
                              label: genre,
                              selected: genre == _genre,
                              onTap: () => setState(
                                  () => _genre = genre == _genre ? null : genre),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlide(
                  controller: _enter,
                  begin: 0.5,
                  end: 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Vibe', hint: 'Pick one'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final vibe in _vibes)
                            _OptionChip(
                              label: vibe,
                              selected: vibe == _vibe,
                              onTap: () => setState(
                                  () => _vibe = vibe == _vibe ? null : vibe),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                FadeSlide(
                  controller: _enter,
                  begin: 0.6,
                  end: 1.0,
                  child: PressScale(
                    onTap: _saving ? null : _upload,
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SwaramColors.amber,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _saving
                            ? const SizedBox(
                                key: ValueKey('saving'),
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: SwaramColors.onAmber,
                                ),
                              )
                            : const Text(
                                'Upload',
                                key: ValueKey('label'),
                                style: TextStyle(
                                  color: SwaramColors.onAmber,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
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
    );
  }
}

/// Rounded chip used for language, genre and vibe.
class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final String? hint;
  const _Label(this.text, {this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: SwaramColors.textSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Text(
              hint!,
              style: const TextStyle(
                color: SwaramColors.muted,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}