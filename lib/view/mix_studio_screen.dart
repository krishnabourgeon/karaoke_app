// import 'package:flutter/material.dart';
// import 'package:karaoke_app/model/mix_settings.dart';
// import 'package:karaoke_app/model/recording_take.dart';
// import 'package:karaoke_app/provider/mix_studio_controller.dart';
// import 'package:karaoke_app/service/karaoke_files.dart';
// import 'package:karaoke_app/service/waveform_service.dart';
// import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';
// import 'package:karaoke_app/view/mix_result_screen.dart';

// /// Mix a saved take as often as the user likes: levels, timing, trims,
// /// effects and presets, with rendered previews and a final export.
// class MixStudioScreen extends StatefulWidget {
//   final RecordingTake take;
//   const MixStudioScreen({super.key, required this.take});

//   static Route<void> route(RecordingTake take) =>
//       MaterialPageRoute<void>(builder: (_) => MixStudioScreen(take: take));

//   @override
//   State<MixStudioScreen> createState() => _MixStudioScreenState();
// }

// class _MixStudioScreenState extends State<MixStudioScreen> {
//   late final MixStudioController _c = MixStudioController(widget.take)..init();

//   @override
//   void dispose() {
//     _c.dispose();
//     super.dispose();
//   }

//   Future<void> _export() async {
//     final choice = await showModalBottomSheet<(ExportFormat, bool)>(
//       context: context,
//       backgroundColor: SwaramColors.card,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) => _ExportSheet(hasVideo: _c.hasVideo),
//     );
//     if (choice == null || !mounted) return;
//     try {
//       final output = await _c.export(format: choice.$1, withVideo: choice.$2);
//       if (!mounted) return;
//       if (choice.$2 && !output.isVideo) {
//         _snack('The video could not be made, so your song was saved as audio.');
//       }
//       await Navigator.of(context).push(
//           MixResultScreen.route(track: _c.take.track, output: output));
//     } on KaraokeException catch (e) {
//       if (mounted) _snack(e.message);
//     }
//   }

//   void _snack(String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(SnackBar(
//         backgroundColor: SwaramColors.card,
//         behavior: SnackBarBehavior.floating,
//         content: Text(message, style: const TextStyle(color: SwaramColors.text)),
//       ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: _c,
//       builder: (context, _) => Scaffold(
//         backgroundColor: SwaramColors.bg,
//         appBar: AppBar(
//           backgroundColor: SwaramColors.bg,
//           foregroundColor: SwaramColors.text,
//           title: const Text('Mix Studio',
//               style: TextStyle(fontWeight: FontWeight.w800)),
//           actions: [
//             IconButton(
//               tooltip: 'Undo',
//               onPressed: _c.canUndo ? _c.undo : null,
//               icon: const Icon(Icons.undo_rounded),
//             ),
//             IconButton(
//               tooltip: 'Reset to default',
//               onPressed: _c.status == StudioStatus.ready ? _c.reset : null,
//               icon: const Icon(Icons.restart_alt_rounded),
//             ),
//           ],
//         ),
//         body: Stack(
//           children: [
//             switch (_c.status) {
//               StudioStatus.loading => _Message(
//                   icon: Icons.downloading_rounded,
//                   text: 'Getting the karaoke track ready…',
//                   progress: _c.loadProgress ?? -1,
//                 ),
//               StudioStatus.error => _Message(
//                   icon: Icons.error_outline_rounded,
//                   text: _c.error ?? 'Something went wrong.',
//                   action: TextButton(onPressed: _c.init, child: const Text('Try again')),
//                 ),
//               StudioStatus.ready => _buildStudio(),
//             },
//             if (_c.exporting) _buildExporting(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStudio() {
//     final s = _c.settings;
//     final full = _c.fullSongMs;
//     final maxTrim = (full ~/ 2).clamp(0, 30000).toDouble();

//     return Column(
//       children: [
//         Expanded(
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 720),
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
//                 children: [
//                   _Header(take: _c.take, songMs: full),
//                   const SizedBox(height: 14),
//                   _WaveformView(controller: _c),
//                   const SizedBox(height: 10),
//                   _Transport(controller: _c),
//                   if (_c.error != null && !_c.rendering)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: Text(_c.error!,
//                           style: const TextStyle(color: SwaramColors.pinkSoft)),
//                     ),
//                   const SizedBox(height: 16),
//                   const _SectionTitle('Presets'),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       for (final p in kMixPresets)
//                         ChoiceChip(
//                           label: Text(p.name),
//                           selected: s.presetId == p.id,
//                           onSelected: (_) => _c.applyPreset(p),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   _Section(title: 'Levels', initiallyExpanded: true, children: [
//                     _StudioSlider(
//                       label: 'Music',
//                       value: s.musicVolume,
//                       max: MixSettings.musicMax,
//                       text: '${(s.musicVolume * 100).round()}%',
//                       onStart: _c.beginEdit,
//                       onChanged: (v) => _c.edit(s.copyWith(musicVolume: v, presetId: 'custom')),
//                     ),
//                     _StudioSlider(
//                       label: 'Vocals',
//                       value: s.vocalVolume,
//                       max: MixSettings.vocalMax,
//                       text: '${(s.vocalVolume * 100).round()}%',
//                       onStart: _c.beginEdit,
//                       onChanged: (v) => _c.edit(s.copyWith(vocalVolume: v, presetId: 'custom')),
//                     ),
//                     Wrap(spacing: 8, children: [
//                       FilterChip(
//                         label: const Text('Mute music'),
//                         selected: s.muteMusic,
//                         onSelected: (v) => _c.apply(s.copyWith(muteMusic: v)),
//                       ),
//                       FilterChip(
//                         label: const Text('Mute vocals'),
//                         selected: s.muteVocals,
//                         onSelected: (v) => _c.apply(s.copyWith(muteVocals: v)),
//                       ),
//                     ]),
//                   ]),
//                   _Section(title: 'Timing', children: [
//                     _StudioSlider(
//                       label: 'Vocal sync',
//                       value: s.offsetMs.toDouble(),
//                       min: -MixSettings.offsetLimitMs.toDouble(),
//                       max: MixSettings.offsetLimitMs.toDouble(),
//                       divisions: 100,
//                       text: _offsetText(s.offsetMs),
//                       onStart: _c.beginEdit,
//                       onChanged: (v) => _c.edit(s.copyWith(offsetMs: v.round())),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         OutlinedButton(
//                           onPressed: () => _c.apply(s.copyWith(offsetMs: s.offsetMs - 10)),
//                           child: const Text('−10 ms'),
//                         ),
//                         const SizedBox(width: 12),
//                         OutlinedButton(
//                           onPressed: () => _c.apply(s.copyWith(offsetMs: s.offsetMs + 10)),
//                           child: const Text('+10 ms'),
//                         ),
//                       ],
//                     ),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 6),
//                       child: Text(
//                         'Voice sounding late? Move it earlier. Bluetooth headphones '
//                         'often need 150–300 ms earlier.',
//                         style: TextStyle(color: SwaramColors.muted, fontSize: 12.5),
//                       ),
//                     ),
//                     if (maxTrim > 0) ...[
//                       _StudioSlider(
//                         label: 'Trim start',
//                         value: s.trimStartMs.clamp(0, maxTrim).toDouble(),
//                         max: maxTrim,
//                         text: _fmt(s.trimStartMs),
//                         onStart: _c.beginEdit,
//                         onChanged: (v) => _c.edit(s.copyWith(trimStartMs: v.round())),
//                       ),
//                       _StudioSlider(
//                         label: 'Trim end',
//                         value: s.trimEndMs.clamp(0, maxTrim).toDouble(),
//                         max: maxTrim,
//                         text: _fmt(s.trimEndMs),
//                         onStart: _c.beginEdit,
//                         onChanged: (v) => _c.edit(s.copyWith(trimEndMs: v.round())),
//                       ),
//                     ],
//                   ]),
//                   _Section(title: 'Voice effects', children: [
//                     _StudioSlider(
//                       label: 'Noise reduction',
//                       value: s.noiseReduction,
//                       text: _pct(s.noiseReduction),
//                       onStart: _c.beginEdit,
//                       onChanged: (v) => _c.edit(s.copyWith(noiseReduction: v, presetId: 'custom')),
//                     ),
//                     for (final (label, value, change) in [
//                       ('Bass', s.bassDb, (double v) => s.copyWith(bassDb: v, presetId: 'custom')),
//                       ('Mid', s.midDb, (double v) => s.copyWith(midDb: v, presetId: 'custom')),
//                       ('Treble', s.trebleDb, (double v) => s.copyWith(trebleDb: v, presetId: 'custom')),
//                     ])
//                       _StudioSlider(
//                         label: label,
//                         value: value,
//                         min: -MixSettings.eqLimitDb,
//                         max: MixSettings.eqLimitDb,
//                         divisions: 48,
//                         text: '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)} dB',
//                         onStart: _c.beginEdit,
//                         onChanged: (v) => _c.edit(change(v)),
//                       ),
//                     _StudioSlider(
//                       label: 'Compression',
//                       value: s.compression,
//                       text: s.compression == 0 ? 'Off' : _pct(s.compression),
//                       onStart: _c.beginEdit,
//                       onChanged: (v) => _c.edit(s.copyWith(compression: v, presetId: 'custom')),
//                     ),
//                     const SizedBox(height: 6),
//                     Wrap(
//                       spacing: 8,
//                       children: [
//                         for (final r in ReverbType.values)
//                           ChoiceChip(
//                             label: Text(r == ReverbType.none ? 'Dry' : _title(r.name)),
//                             selected: s.reverb == r,
//                             onSelected: (_) => _c.apply(s.copyWith(
//                               reverb: r,
//                               reverbAmount: r != ReverbType.none && s.reverbAmount == 0
//                                   ? 0.3
//                                   : s.reverbAmount,
//                               presetId: 'custom',
//                             )),
//                           ),
//                       ],
//                     ),
//                     if (s.reverb != ReverbType.none)
//                       _StudioSlider(
//                         label: 'Reverb',
//                         value: s.reverbAmount,
//                         text: _pct(s.reverbAmount),
//                         onStart: _c.beginEdit,
//                         onChanged: (v) => _c.edit(s.copyWith(reverbAmount: v, presetId: 'custom')),
//                       ),
//                     _StudioSlider(
//                       label: 'Echo',
//                       value: s.echoAmount,
//                       text: s.echoAmount == 0 ? 'Off' : _pct(s.echoAmount),
//                       onStart: _c.beginEdit,
//                       onChanged: (v) => _c.edit(s.copyWith(echoAmount: v, presetId: 'custom')),
//                     ),
//                     if (s.echoAmount > 0)
//                       _StudioSlider(
//                         label: 'Echo delay',
//                         value: s.echoDelayMs.toDouble(),
//                         min: 120,
//                         max: 800,
//                         divisions: 68,
//                         text: '${s.echoDelayMs} ms',
//                         onStart: _c.beginEdit,
//                         onChanged: (v) => _c.edit(s.copyWith(echoDelayMs: v.round(), presetId: 'custom')),
//                       ),
//                     const Text(
//                       'A limiter on the final mix keeps peaks below −1 dB so the song never clips.',
//                       style: TextStyle(color: SwaramColors.muted, fontSize: 12.5),
//                     ),
//                   ]),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         SafeArea(
//           top: false,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//             child: SizedBox(
//               width: double.infinity,
//               child: FilledButton.icon(
//                 onPressed: _c.exporting ? null : _export,
//                 icon: const Icon(Icons.auto_awesome_rounded),
//                 label: const Text('Create my song'),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildExporting() => Positioned.fill(
//         child: Container(
//           color: SwaramColors.bg.withAlpha(235),
//           alignment: Alignment.center,
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Mixing your song…',
//                   style: TextStyle(
//                       color: SwaramColors.text,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w800)),
//               const SizedBox(height: 16),
//               LinearProgressIndicator(value: _c.exportProgress),
//               const SizedBox(height: 8),
//               Text('${(_c.exportProgress * 100).round()}%',
//                   style: const TextStyle(color: SwaramColors.muted)),
//               const SizedBox(height: 12),
//               TextButton(onPressed: _c.cancelExport, child: const Text('Cancel')),
//             ],
//           ),
//         ),
//       );

//   static String _offsetText(int ms) => ms == 0
//       ? 'In sync'
//       : '${ms.abs()} ms ${ms > 0 ? 'later' : 'earlier'}';
//   static String _pct(double v) => '${(v * 100).round()}%';
//   static String _title(String s) => s[0].toUpperCase() + s.substring(1);
// }

// String _fmt(int ms) {
//   final d = Duration(milliseconds: ms);
//   final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//   return '${d.inMinutes}:$s';
// }

// class _Header extends StatelessWidget {
//   final RecordingTake take;
//   final int songMs;
//   const _Header({required this.take, required this.songMs});

//   @override
//   Widget build(BuildContext context) {
//     final color = trackColor(take.track);
//     return Row(
//       children: [
//         Container(
//           width: 56,
//           height: 56,
//           decoration: BoxDecoration(
//             color: color.withAlpha(40),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Icon(
//             take.track.isVideo ? Icons.movie_rounded : Icons.music_note_rounded,
//             color: color,
//           ),
//         ),
//         const SizedBox(width: 14),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(take.title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                       color: SwaramColors.text,
//                       fontSize: 17,
//                       fontWeight: FontWeight.w800)),
//               const SizedBox(height: 2),
//               Text('${take.track.language} · ${_fmt(songMs)}',
//                   style: const TextStyle(color: SwaramColors.muted, fontSize: 13)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _Transport extends StatelessWidget {
//   final MixStudioController controller;
//   const _Transport({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     final c = controller;
//     return Column(
//       children: [
//         Row(
//           children: [
//             Text(_fmt(c.playheadMs),
//                 style: const TextStyle(color: SwaramColors.textSoft)),
//             const Spacer(),
//             SizedBox(
//               width: 64,
//               height: 64,
//               child: c.rendering
//                   ? Stack(alignment: Alignment.center, children: [
//                       CircularProgressIndicator(value: c.renderProgress),
//                       IconButton(
//                         tooltip: 'Stop preparing preview',
//                         onPressed: c.cancelRender,
//                         icon: const Icon(Icons.close_rounded, color: SwaramColors.text),
//                       ),
//                     ])
//                   : IconButton.filled(
//                       tooltip: c.playing ? 'Pause' : 'Preview',
//                       iconSize: 34,
//                       onPressed: c.togglePlay,
//                       icon: Icon(c.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
//                     ),
//             ),
//             const Spacer(),
//             Text(_fmt(c.fullSongMs),
//                 style: const TextStyle(color: SwaramColors.muted)),
//           ],
//         ),
//         const SizedBox(height: 10),
//         SegmentedButton<PreviewMode>(
//           segments: const [
//             ButtonSegment(value: PreviewMode.after, label: Text('After')),
//             ButtonSegment(value: PreviewMode.before, label: Text('Before')),
//             ButtonSegment(value: PreviewMode.raw, label: Text('Raw vocals')),
//           ],
//           selected: {c.mode},
//           onSelectionChanged: (v) => c.setMode(v.first),
//         ),
//         const SizedBox(height: 4),
//         const Text('Previews play 20 seconds from the playhead.',
//             style: TextStyle(color: SwaramColors.muted, fontSize: 12)),
//       ],
//     );
//   }
// }

// /// Music on top, vocals below (shifted by the timing), trims shaded,
// /// playhead line. Tap or drag to move the playhead.
// class _WaveformView extends StatelessWidget {
//   final MixStudioController controller;
//   const _WaveformView({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     final c = controller;
//     final full = c.fullSongMs;
//     return LayoutBuilder(builder: (context, box) {
//       void seekTo(double dx) {
//         if (full <= 0) return;
//         c.seek((dx / box.maxWidth * full).round());
//       }

//       return GestureDetector(
//         onTapDown: (d) => seekTo(d.localPosition.dx),
//         onHorizontalDragUpdate: (d) => seekTo(d.localPosition.dx),
//         child: Container(
//           height: 132,
//           decoration: BoxDecoration(
//             color: SwaramColors.card,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: SwaramColors.border),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: CustomPaint(
//               size: Size(box.maxWidth, 132),
//               painter: _WavePainter(
//                 music: c.musicWave,
//                 vocals: c.vocalWave,
//                 songMs: full,
//                 vocalLeadMs: c.musicOffsetMs - c.settings.offsetMs,
//                 trimStartMs: c.settings.trimStartMs,
//                 trimEndMs: c.settings.trimEndMs,
//                 playheadMs: c.playheadMs,
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }

// class _WavePainter extends CustomPainter {
//   final Waveform? music;
//   final Waveform? vocals;
//   final int songMs;
//   final int vocalLeadMs; // vocal time at song time 0
//   final int trimStartMs;
//   final int trimEndMs;
//   final int playheadMs;

//   _WavePainter({
//     required this.music,
//     required this.vocals,
//     required this.songMs,
//     required this.vocalLeadMs,
//     required this.trimStartMs,
//     required this.trimEndMs,
//     required this.playheadMs,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (songMs <= 0) return;
//     final half = size.height / 2;
//     _lane(canvas, size, music, 0, half, 0, SwaramColors.teal);
//     _lane(canvas, size, vocals, half, half, vocalLeadMs, SwaramColors.amber);

//     final shade = Paint()..color = SwaramColors.bg.withAlpha(170);
//     final pxPerMs = size.width / songMs;
//     if (trimStartMs > 0) {
//       canvas.drawRect(Rect.fromLTWH(0, 0, trimStartMs * pxPerMs, size.height), shade);
//     }
//     if (trimEndMs > 0) {
//       final x = (songMs - trimEndMs) * pxPerMs;
//       canvas.drawRect(Rect.fromLTWH(x, 0, size.width - x, size.height), shade);
//     }
//     final x = playheadMs * pxPerMs;
//     canvas.drawLine(Offset(x, 0), Offset(x, size.height),
//         Paint()
//           ..color = SwaramColors.pink
//           ..strokeWidth = 2);
//   }

//   /// Draws [wave] so that its time [leadMs] lines up with song time 0.
//   void _lane(Canvas canvas, Size size, Waveform? wave, double top, double height,
//       int leadMs, Color color) {
//     final mid = top + height / 2;
//     if (wave == null || wave.peaks.isEmpty || wave.duration.inMilliseconds == 0) {
//       canvas.drawLine(Offset(0, mid), Offset(size.width, mid),
//           Paint()..color = color.withAlpha(80));
//       return;
//     }
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 1.5;
//     final waveMs = wave.duration.inMilliseconds;
//     final columns = size.width ~/ 3;
//     for (var i = 0; i < columns; i++) {
//       final songT = i / columns * songMs;
//       final waveT = songT + leadMs;
//       if (waveT < 0 || waveT >= waveMs) continue;
//       final peak = wave.peaks[(waveT / waveMs * wave.peaks.length)
//           .floor()
//           .clamp(0, wave.peaks.length - 1)];
//       final h = (peak * (height / 2 - 6)).clamp(1.0, height / 2);
//       final x = i * 3.0 + 1;
//       canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), paint);
//     }
//   }

//   @override
//   bool shouldRepaint(_WavePainter old) =>
//       old.music != music ||
//       old.vocals != vocals ||
//       old.songMs != songMs ||
//       old.vocalLeadMs != vocalLeadMs ||
//       old.trimStartMs != trimStartMs ||
//       old.trimEndMs != trimEndMs ||
//       old.playheadMs != playheadMs;
// }

// class _SectionTitle extends StatelessWidget {
//   final String text;
//   const _SectionTitle(this.text);

//   @override
//   Widget build(BuildContext context) => Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: Text(text,
//             style: const TextStyle(
//                 color: SwaramColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
//       );
// }

// class _Section extends StatelessWidget {
//   final String title;
//   final bool initiallyExpanded;
//   final List<Widget> children;
//   const _Section({required this.title, required this.children, this.initiallyExpanded = false});

//   @override
//   Widget build(BuildContext context) => Card(
//         color: SwaramColors.card,
//         margin: const EdgeInsets.only(bottom: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//           side: const BorderSide(color: SwaramColors.border),
//         ),
//         child: ExpansionTile(
//           initiallyExpanded: initiallyExpanded,
//           shape: const Border(),
//           collapsedShape: const Border(),
//           iconColor: SwaramColors.text,
//           collapsedIconColor: SwaramColors.muted,
//           title: Text(title,
//               style: const TextStyle(
//                   color: SwaramColors.text, fontWeight: FontWeight.w800)),
//           childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//           children: children,
//         ),
//       );
// }

// class _StudioSlider extends StatelessWidget {
//   final String label;
//   final double value;
//   final double min;
//   final double max;
//   final int? divisions;
//   final String text;
//   final VoidCallback onStart;
//   final ValueChanged<double> onChanged;

//   const _StudioSlider({
//     required this.label,
//     required this.value,
//     required this.text,
//     required this.onStart,
//     required this.onChanged,
//     this.min = 0,
//     this.max = 1,
//     this.divisions,
//   });

//   @override
//   Widget build(BuildContext context) => Row(
//         children: [
//           SizedBox(
//             width: 104,
//             child: Text(label, style: const TextStyle(color: SwaramColors.textSoft)),
//           ),
//           Expanded(
//             child: Slider(
//               value: value.clamp(min, max),
//               min: min,
//               max: max,
//               divisions: divisions,
//               onChangeStart: (_) => onStart(),
//               onChanged: onChanged,
//             ),
//           ),
//           SizedBox(
//             width: 92,
//             child: Text(text,
//                 textAlign: TextAlign.end,
//                 style: const TextStyle(color: SwaramColors.muted, fontSize: 12.5)),
//           ),
//         ],
//       );
// }

// class _ExportSheet extends StatefulWidget {
//   final bool hasVideo;
//   const _ExportSheet({required this.hasVideo});

//   @override
//   State<_ExportSheet> createState() => _ExportSheetState();
// }

// class _ExportSheetState extends State<_ExportSheet> {
//   ExportFormat _format = ExportFormat.m4a;
//   late bool _video = widget.hasVideo;

//   @override
//   Widget build(BuildContext context) => SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Save your song',
//                   style: TextStyle(
//                       color: SwaramColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
//               const SizedBox(height: 8),
//               if (widget.hasVideo)
//                 SwitchListTile(
//                   contentPadding: EdgeInsets.zero,
//                   title: const Text('Include the video',
//                       style: TextStyle(color: SwaramColors.text)),
//                   subtitle: const Text('Saved as MP4. The start trim is not applied to video.',
//                       style: TextStyle(color: SwaramColors.muted)),
//                   value: _video,
//                   onChanged: (v) => setState(() => _video = v),
//                 ),
//               if (!_video)
//                 RadioGroup<ExportFormat>(
//                   groupValue: _format,
//                   onChanged: (v) => setState(() => _format = v ?? _format),
//                   child: Column(children: [
//                     for (final f in ExportFormat.values)
//                       RadioListTile<ExportFormat>(
//                         contentPadding: EdgeInsets.zero,
//                         value: f,
//                         title: Text(f.label, style: const TextStyle(color: SwaramColors.text)),
//                       ),
//                   ]),
//                 ),
//               const SizedBox(height: 8),
//               SizedBox(
//                 width: double.infinity,
//                 child: FilledButton(
//                   onPressed: () => Navigator.pop(context, (_format, _video)),
//                   child: const Text('Create'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
// }

// class _Message extends StatelessWidget {
//   final IconData icon;
//   final String text;
//   final double? progress; // -1 = indeterminate
//   final Widget? action;
//   const _Message({required this.icon, required this.text, this.progress, this.action});

//   @override
//   Widget build(BuildContext context) => Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, color: SwaramColors.muted, size: 40),
//               const SizedBox(height: 12),
//               Text(text,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: SwaramColors.text)),
//               if (progress != null) ...[
//                 const SizedBox(height: 16),
//                 LinearProgressIndicator(value: progress! < 0 ? null : progress),
//               ],
//               if (action != null) ...[const SizedBox(height: 12), action!],
//             ],
//           ),
//         ),
//       );
// }




import 'package:flutter/material.dart';
import 'package:karaoke_app/model/mix_settings.dart';
import 'package:karaoke_app/model/recording_take.dart';
import 'package:karaoke_app/provider/mix_studio_controller.dart';
import 'package:karaoke_app/service/karaoke_files.dart';
import 'package:karaoke_app/service/waveform_service.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/mix_result_screen.dart';

/// Mix a saved take as often as the user likes: levels, timing, trims,
/// effects and presets, with rendered previews and a final export.
class MixStudioScreen extends StatefulWidget {
  final RecordingTake take;
  const MixStudioScreen({super.key, required this.take});

  static Route<void> route(RecordingTake take) =>
      MaterialPageRoute<void>(builder: (_) => MixStudioScreen(take: take));

  @override
  State<MixStudioScreen> createState() => _MixStudioScreenState();
}

class _MixStudioScreenState extends State<MixStudioScreen> {
  late final MixStudioController _c = MixStudioController(widget.take)..init();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final choice = await showModalBottomSheet<(ExportFormat, bool)>(
      context: context,
      backgroundColor: SwaramColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ExportSheet(hasVideo: _c.hasVideo),
    );
    if (choice == null || !mounted) return;
    try {
      final output = await _c.export(format: choice.$1, withVideo: choice.$2);
      if (!mounted) return;
      if (choice.$2 && !output.isVideo) {
        _snack('The video could not be made, so your song was saved as audio.');
      }
      await Navigator.of(context).push(
          MixResultScreen.route(track: _c.take.track, output: output));
    } on KaraokeException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: SwaramColors.card,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(color: SwaramColors.text)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) => Scaffold(
        backgroundColor: SwaramColors.bg,
        appBar: AppBar(
          backgroundColor: SwaramColors.bg,
          foregroundColor: SwaramColors.text,
          title: const Text('Mix Studio',
              style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: _c.canUndo ? _c.undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: 'Reset to default',
              onPressed: _c.status == StudioStatus.ready ? _c.reset : null,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            switch (_c.status) {
              StudioStatus.loading => _Message(
                  icon: Icons.downloading_rounded,
                  text: 'Getting the karaoke track ready…',
                  progress: _c.loadProgress ?? -1,
                ),
              StudioStatus.error => _Message(
                  icon: Icons.error_outline_rounded,
                  text: _c.error ?? 'Something went wrong.',
                  action: TextButton(onPressed: _c.init, child: const Text('Try again')),
                ),
              StudioStatus.ready => _buildStudio(),
            },
            if (_c.exporting) _buildExporting(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudio() {
    final s = _c.settings;
    final full = _c.fullSongMs;
    final maxTrim = (full ~/ 2).clamp(0, 30000).toDouble();

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _Header(take: _c.take, songMs: full),
                  const SizedBox(height: 14),
                  _WaveformView(controller: _c),
                  const SizedBox(height: 10),
                  _Transport(controller: _c),
                  if (_c.error != null && !_c.rendering)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_c.error!,
                          style: const TextStyle(color: SwaramColors.pinkSoft)),
                    ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Presets'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in kMixPresets)
                        ChoiceChip(
                          label: Text(p.name),
                          selected: s.presetId == p.id,
                          onSelected: (_) => _c.applyPreset(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(title: 'Levels', initiallyExpanded: true, children: [
                    _StudioSlider(
                      label: 'Music',
                      value: s.musicVolume,
                      max: MixSettings.musicMax,
                      text: '${(s.musicVolume * 100).round()}%',
                      onStart: _c.beginEdit,
                      onChanged: (v) => _c.edit(s.copyWith(musicVolume: v, presetId: 'custom')),
                    ),
                    _StudioSlider(
                      label: 'Vocals',
                      value: s.vocalVolume,
                      max: MixSettings.vocalMax,
                      text: '${(s.vocalVolume * 100).round()}%',
                      onStart: _c.beginEdit,
                      onChanged: (v) => _c.edit(s.copyWith(vocalVolume: v, presetId: 'custom')),
                    ),
                    Wrap(spacing: 8, children: [
                      FilterChip(
                        label: const Text('Mute music'),
                        selected: s.muteMusic,
                        onSelected: (v) => _c.apply(s.copyWith(muteMusic: v)),
                      ),
                      FilterChip(
                        label: const Text('Mute vocals'),
                        selected: s.muteVocals,
                        onSelected: (v) => _c.apply(s.copyWith(muteVocals: v)),
                      ),
                    ]),
                  ]),
                  _Section(title: 'Timing', children: [
                    _StudioSlider(
                      label: 'Vocal sync',
                      value: s.offsetMs.toDouble(),
                      min: -MixSettings.offsetLimitMs.toDouble(),
                      max: MixSettings.offsetLimitMs.toDouble(),
                      divisions: 100,
                      text: _offsetText(s.offsetMs),
                      onStart: _c.beginEdit,
                      onChanged: (v) => _c.edit(s.copyWith(offsetMs: v.round())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => _c.apply(s.copyWith(offsetMs: s.offsetMs - 10)),
                          child: const Text('−10 ms'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => _c.apply(s.copyWith(offsetMs: s.offsetMs + 10)),
                          child: const Text('+10 ms'),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Voice sounding late? Move it earlier. Bluetooth headphones '
                        'often need 150–300 ms earlier.',
                        style: TextStyle(color: SwaramColors.muted, fontSize: 12.5),
                      ),
                    ),
                    if (maxTrim > 0) ...[
                      _StudioSlider(
                        label: 'Trim start',
                        value: s.trimStartMs.clamp(0, maxTrim).toDouble(),
                        max: maxTrim,
                        text: _fmt(s.trimStartMs),
                        onStart: _c.beginEdit,
                        onChanged: (v) => _c.edit(s.copyWith(trimStartMs: v.round())),
                      ),
                      _StudioSlider(
                        label: 'Trim end',
                        value: s.trimEndMs.clamp(0, maxTrim).toDouble(),
                        max: maxTrim,
                        text: _fmt(s.trimEndMs),
                        onStart: _c.beginEdit,
                        onChanged: (v) => _c.edit(s.copyWith(trimEndMs: v.round())),
                      ),
                    ],
                  ]),
                  _Section(title: 'Voice effects', children: [
                    _StudioSlider(
                      label: 'Noise reduction',
                      value: s.noiseReduction,
                      text: _pct(s.noiseReduction),
                      onStart: _c.beginEdit,
                      onChanged: (v) => _c.edit(s.copyWith(noiseReduction: v, presetId: 'custom')),
                    ),
                    for (final (label, value, change) in [
                      ('Bass', s.bassDb, (double v) => s.copyWith(bassDb: v, presetId: 'custom')),
                      ('Mid', s.midDb, (double v) => s.copyWith(midDb: v, presetId: 'custom')),
                      ('Treble', s.trebleDb, (double v) => s.copyWith(trebleDb: v, presetId: 'custom')),
                    ])
                      _StudioSlider(
                        label: label,
                        value: value,
                        min: -MixSettings.eqLimitDb,
                        max: MixSettings.eqLimitDb,
                        divisions: 48,
                        text: '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)} dB',
                        onStart: _c.beginEdit,
                        onChanged: (v) => _c.edit(change(v)),
                      ),
                    _StudioSlider(
                      label: 'Compression',
                      value: s.compression,
                      text: s.compression == 0 ? 'Off' : _pct(s.compression),
                      onStart: _c.beginEdit,
                      onChanged: (v) => _c.edit(s.copyWith(compression: v, presetId: 'custom')),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final r in ReverbType.values)
                          ChoiceChip(
                            label: Text(r == ReverbType.none ? 'Dry' : _title(r.name)),
                            selected: s.reverb == r,
                            onSelected: (_) => _c.apply(s.copyWith(
                              reverb: r,
                              reverbAmount: r != ReverbType.none && s.reverbAmount == 0
                                  ? 0.3
                                  : s.reverbAmount,
                              presetId: 'custom',
                            )),
                          ),
                      ],
                    ),
                    if (s.reverb != ReverbType.none)
                      _StudioSlider(
                        label: 'Reverb',
                        value: s.reverbAmount,
                        text: _pct(s.reverbAmount),
                        onStart: _c.beginEdit,
                        onChanged: (v) => _c.edit(s.copyWith(reverbAmount: v, presetId: 'custom')),
                      ),
                    _StudioSlider(
                      label: 'Echo',
                      value: s.echoAmount,
                      text: s.echoAmount == 0 ? 'Off' : _pct(s.echoAmount),
                      onStart: _c.beginEdit,
                      onChanged: (v) => _c.edit(s.copyWith(echoAmount: v, presetId: 'custom')),
                    ),
                    if (s.echoAmount > 0)
                      _StudioSlider(
                        label: 'Echo delay',
                        value: s.echoDelayMs.toDouble(),
                        min: 120,
                        max: 800,
                        divisions: 68,
                        text: '${s.echoDelayMs} ms',
                        onStart: _c.beginEdit,
                        onChanged: (v) => _c.edit(s.copyWith(echoDelayMs: v.round(), presetId: 'custom')),
                      ),
                    // const Text(
                    //   'A limiter on the final mix keeps peaks below −1 dB so the song never clips.',
                    //   style: TextStyle(color: SwaramColors.muted, fontSize: 12.5),
                    // ),
                  ]),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _c.exporting ? null : _export,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Create my song'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExporting() => Positioned.fill(
        child: Container(
          color: SwaramColors.bg.withAlpha(235),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mixing your song…',
                  style: TextStyle(
                      color: SwaramColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _c.exportProgress),
              const SizedBox(height: 8),
              Text('${(_c.exportProgress * 100).round()}%',
                  style: const TextStyle(color: SwaramColors.muted)),
              const SizedBox(height: 12),
              TextButton(onPressed: _c.cancelExport, child: const Text('Cancel')),
            ],
          ),
        ),
      );

  static String _offsetText(int ms) => ms == 0
      ? 'In sync'
      : '${ms.abs()} ms ${ms > 0 ? 'later' : 'earlier'}';
  static String _pct(double v) => '${(v * 100).round()}%';
  static String _title(String s) => s[0].toUpperCase() + s.substring(1);
}

String _fmt(int ms) {
  final d = Duration(milliseconds: ms);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$s';
}

class _Header extends StatelessWidget {
  final RecordingTake take;
  final int songMs;
  const _Header({required this.take, required this.songMs});

  @override
  Widget build(BuildContext context) {
    final color = trackColor(take.track);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            take.track.isVideo ? Icons.movie_rounded : Icons.music_note_rounded,
            color: color,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(take.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: SwaramColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${take.track.language} · ${_fmt(songMs)}',
                  style: const TextStyle(color: SwaramColors.muted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Transport extends StatelessWidget {
  final MixStudioController controller;
  const _Transport({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      children: [
        Row(
          children: [
            Text(_fmt(c.playheadMs),
                style: const TextStyle(color: SwaramColors.textSoft)),
            const Spacer(),
            SizedBox(
              width: 64,
              height: 64,
              child: c.rendering
                  ? Stack(alignment: Alignment.center, children: [
                      CircularProgressIndicator(value: c.renderProgress),
                      IconButton(
                        tooltip: 'Stop preparing preview',
                        onPressed: c.cancelRender,
                        icon: const Icon(Icons.close_rounded, color: SwaramColors.text),
                      ),
                    ])
                  : IconButton.filled(
                      tooltip: c.playing ? 'Pause' : 'Preview',
                      iconSize: 34,
                      onPressed: c.togglePlay,
                      icon: Icon(c.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
            ),
            const Spacer(),
            Text(_fmt(c.fullSongMs),
                style: const TextStyle(color: SwaramColors.muted)),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedButton<PreviewMode>(
          segments: const [
            ButtonSegment(value: PreviewMode.after, label: Text('After')),
            ButtonSegment(value: PreviewMode.before, label: Text('Before')),
            ButtonSegment(value: PreviewMode.raw, label: Text('Raw vocals')),
          ],
          selected: {c.mode},
          onSelectionChanged: (v) => c.setMode(v.first),
        ),
        const SizedBox(height: 4),
        const Text('Previews play 20 seconds from the playhead.',
            style: TextStyle(color: SwaramColors.muted, fontSize: 12)),
      ],
    );
  }
}

/// Music on top, vocals below (shifted by the timing), trims shaded,
/// playhead line. Tap or drag to move the playhead.
class _WaveformView extends StatelessWidget {
  final MixStudioController controller;
  const _WaveformView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final full = c.fullSongMs;
    return LayoutBuilder(builder: (context, box) {
      void seekTo(double dx) {
        if (full <= 0) return;
        c.seek((dx / box.maxWidth * full).round());
      }

      return GestureDetector(
        onTapDown: (d) => seekTo(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => seekTo(d.localPosition.dx),
        child: Container(
          height: 132,
          decoration: BoxDecoration(
            color: SwaramColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SwaramColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              size: Size(box.maxWidth, 132),
              painter: _WavePainter(
                music: c.musicWave,
                vocals: c.vocalWave,
                songMs: full,
                vocalLeadMs: c.musicOffsetMs - c.settings.offsetMs,
                trimStartMs: c.settings.trimStartMs,
                trimEndMs: c.settings.trimEndMs,
                playheadMs: c.playheadMs,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _WavePainter extends CustomPainter {
  final Waveform? music;
  final Waveform? vocals;
  final int songMs;
  final int vocalLeadMs; // vocal time at song time 0
  final int trimStartMs;
  final int trimEndMs;
  final int playheadMs;

  _WavePainter({
    required this.music,
    required this.vocals,
    required this.songMs,
    required this.vocalLeadMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.playheadMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (songMs <= 0) return;
    final half = size.height / 2;
    _lane(canvas, size, music, 0, half, 0, SwaramColors.teal);
    _lane(canvas, size, vocals, half, half, vocalLeadMs, SwaramColors.amber);

    final shade = Paint()..color = SwaramColors.bg.withAlpha(170);
    final pxPerMs = size.width / songMs;
    if (trimStartMs > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, trimStartMs * pxPerMs, size.height), shade);
    }
    if (trimEndMs > 0) {
      final x = (songMs - trimEndMs) * pxPerMs;
      canvas.drawRect(Rect.fromLTWH(x, 0, size.width - x, size.height), shade);
    }
    final x = playheadMs * pxPerMs;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height),
        Paint()
          ..color = SwaramColors.pink
          ..strokeWidth = 2);
  }

  /// Draws [wave] so that its time [leadMs] lines up with song time 0.
  void _lane(Canvas canvas, Size size, Waveform? wave, double top, double height,
      int leadMs, Color color) {
    final mid = top + height / 2;
    if (wave == null || wave.peaks.isEmpty || wave.duration.inMilliseconds == 0) {
      canvas.drawLine(Offset(0, mid), Offset(size.width, mid),
          Paint()..color = color.withAlpha(80));
      return;
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final waveMs = wave.duration.inMilliseconds;
    final columns = size.width ~/ 3;
    for (var i = 0; i < columns; i++) {
      final songT = i / columns * songMs;
      final waveT = songT + leadMs;
      if (waveT < 0 || waveT >= waveMs) continue;
      final peak = wave.peaks[(waveT / waveMs * wave.peaks.length)
          .floor()
          .clamp(0, wave.peaks.length - 1)];
      final h = (peak * (height / 2 - 6)).clamp(1.0, height / 2);
      final x = i * 3.0 + 1;
      canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.music != music ||
      old.vocals != vocals ||
      old.songMs != songMs ||
      old.vocalLeadMs != vocalLeadMs ||
      old.trimStartMs != trimStartMs ||
      old.trimEndMs != trimEndMs ||
      old.playheadMs != playheadMs;
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: SwaramColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;
  const _Section({required this.title, required this.children, this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context) => Card(
        color: SwaramColors.card,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SwaramColors.border),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: SwaramColors.text,
          collapsedIconColor: SwaramColors.muted,
          title: Text(title,
              style: const TextStyle(
                  color: SwaramColors.text, fontWeight: FontWeight.w800)),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: children,
        ),
      );
}

class _StudioSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String text;
  final VoidCallback onStart;
  final ValueChanged<double> onChanged;

  const _StudioSlider({
    required this.label,
    required this.value,
    required this.text,
    required this.onStart,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: const TextStyle(color: SwaramColors.textSoft)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChangeStart: (_) => onStart(),
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

class _ExportSheet extends StatefulWidget {
  final bool hasVideo;
  const _ExportSheet({required this.hasVideo});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  ExportFormat _format = ExportFormat.m4a;
  late bool _video = widget.hasVideo;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Save your song',
                  style: TextStyle(
                      color: SwaramColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (widget.hasVideo)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include the video',
                      style: TextStyle(color: SwaramColors.text)),
                  subtitle: const Text('Saved as MP4. The start trim is not applied to video.',
                      style: TextStyle(color: SwaramColors.muted)),
                  value: _video,
                  onChanged: (v) => setState(() => _video = v),
                ),
              if (!_video)
                RadioGroup<ExportFormat>(
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v ?? _format),
                  child: Column(children: [
                    for (final f in ExportFormat.values)
                      RadioListTile<ExportFormat>(
                        contentPadding: EdgeInsets.zero,
                        value: f,
                        title: Text(f.label, style: const TextStyle(color: SwaramColors.text)),
                      ),
                  ]),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, (_format, _video)),
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final double? progress; // -1 = indeterminate
  final Widget? action;
  const _Message({required this.icon, required this.text, this.progress, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: SwaramColors.muted, size: 40),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SwaramColors.text)),
              if (progress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress! < 0 ? null : progress),
              ],
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      );
}
