// import 'package:flutter/material.dart';
// import 'package:karaoke_app/model/recording_take.dart';
// import 'package:karaoke_app/service/recordings_store.dart';
// import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
// import 'package:karaoke_app/view/common_widgets/track.dart';
// import 'package:karaoke_app/view/mix_studio_screen.dart';

// /// Saved takes. Each one opens in the Mix Studio, so it can be mixed again
// /// without singing it again.
// class RecordingsScreen extends StatelessWidget {
//   const RecordingsScreen({super.key});

//   static Route<void> route() =>
//       MaterialPageRoute<void>(builder: (_) => const RecordingsScreen());

//   Future<void> _rename(BuildContext context, RecordingTake take) async {
//     final controller = TextEditingController(text: take.title);
//     final name = await showDialog<String>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: SwaramColors.card,
//         title: const Text('Rename', style: TextStyle(color: SwaramColors.text)),
//         content: TextField(
//           controller: controller,
//           autofocus: true,
//           style: const TextStyle(color: SwaramColors.text),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//           TextButton(
//               onPressed: () => Navigator.pop(ctx, controller.text),
//               child: const Text('Save')),
//         ],
//       ),
//     );
//     controller.dispose();
//     if (name != null) await RecordingsStore.instance.rename(take.id, name);
//   }

//   Future<void> _delete(BuildContext context, RecordingTake take) async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: SwaramColors.card,
//         title: const Text('Delete this recording?',
//             style: TextStyle(color: SwaramColors.text)),
//         content: const Text(
//             'Your vocals and every mix made from them will be removed from this device.',
//             style: TextStyle(color: SwaramColors.muted)),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
//         ],
//       ),
//     );
//     if (ok == true) await RecordingsStore.instance.delete(take.id);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: SwaramColors.bg,
//       appBar: AppBar(
//         backgroundColor: SwaramColors.bg,
//         foregroundColor: SwaramColors.text,
//         title: const Text('My recordings', style: TextStyle(fontWeight: FontWeight.w800)),
//       ),
//       body: ListenableBuilder(
//         listenable: RecordingsStore.instance,
//         builder: (context, _) {
//           final takes = RecordingsStore.instance.takes;
//           if (takes.isEmpty) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32),
//                 child: Text('Sing a song and your takes will appear here.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: SwaramColors.muted)),
//               ),
//             );
//           }
//           return ListView.separated(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             itemCount: takes.length,
//             separatorBuilder: (_, _) => const Divider(color: SwaramColors.border, height: 1),
//             itemBuilder: (context, i) {
//               final t = takes[i];
//               final d = t.songLength;
//               final length =
//                   '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
//               final date = MaterialLocalizations.of(context).formatShortDate(t.createdAt);
//               return ListTile(
//                 leading: Icon(Icons.mic_rounded, color: trackColor(t.track)),
//                 title: Text(t.title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(color: SwaramColors.text)),
//                 subtitle: Text(
//                   '$length · $date · ${t.renders.length} '
//                   '${t.renders.length == 1 ? 'mix' : 'mixes'}',
//                   style: const TextStyle(color: SwaramColors.muted),
//                 ),
//                 onTap: () => Navigator.of(context).push(MixStudioScreen.route(t)),
//                 trailing: PopupMenuButton<String>(
//                   iconColor: SwaramColors.muted,
//                   onSelected: (v) => v == 'rename' ? _rename(context, t) : _delete(context, t),
//                   itemBuilder: (_) => const [
//                     PopupMenuItem(value: 'rename', child: Text('Rename')),
//                     PopupMenuItem(value: 'delete', child: Text('Delete')),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:karaoke_app/model/recording_take.dart';
import 'package:karaoke_app/service/recordings_store.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/mix_studio_screen.dart';

/// Saved takes. Each one opens in the Mix Studio, so it can be mixed again
/// without singing it again.
class RecordingsScreen extends StatelessWidget {
  const RecordingsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const RecordingsScreen());

  Future<void> _rename(BuildContext context, RecordingTake take) async {
    final controller = TextEditingController(text: take.title);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SwaramColors.card,
        title: const Text('Rename', style: TextStyle(color: SwaramColors.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: SwaramColors.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name != null) await RecordingsStore.instance.rename(take.id, name);
  }

  Future<void> _delete(BuildContext context, RecordingTake take) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SwaramColors.card,
        title: const Text('Delete this recording?',
            style: TextStyle(color: SwaramColors.text)),
        content: const Text(
            'Your vocals and every mix made from them will be removed from this device.',
            style: TextStyle(color: SwaramColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await RecordingsStore.instance.delete(take.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      appBar: AppBar(
        backgroundColor: SwaramColors.bg,
        foregroundColor: SwaramColors.text,
        title: const Text('My recordings', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: RecordingsStore.instance,
        builder: (context, _) {
          final takes = RecordingsStore.instance.takes;
          if (takes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Sing a song and your takes will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SwaramColors.muted)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: takes.length,
            separatorBuilder: (_, _) => const Divider(color: SwaramColors.border, height: 1),
            itemBuilder: (context, i) {
              final t = takes[i];
              final d = t.songLength;
              final length =
                  '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
              final date = MaterialLocalizations.of(context).formatShortDate(t.createdAt);
              return ListTile(
                leading: Icon(Icons.mic_rounded, color: trackColor(t.track)),
                title: Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: SwaramColors.text)),
                subtitle: Text(
                  '$length · $date · ${t.renders.length} '
                  '${t.renders.length == 1 ? 'mix' : 'mixes'}',
                  style: const TextStyle(color: SwaramColors.muted),
                ),
                onTap: () => Navigator.of(context).push(MixStudioScreen.route(t)),
                trailing: PopupMenuButton<String>(
                  iconColor: SwaramColors.muted,
                  onSelected: (v) => v == 'rename' ? _rename(context, t) : _delete(context, t),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
