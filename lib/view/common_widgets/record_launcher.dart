import 'package:flutter/material.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/library_store.dart';
import 'package:karaoke_app/view/record_screen.dart';

/// One place to start singing, so every screen opens the record screen the same way.

/// Opens the record screen for [track].
void openRecordFor(BuildContext context, Track track) {
  Navigator.of(context).push(RecordScreen.route(track));
}

/// Lets the user pick any song or uploaded video, then opens the record screen.
void openRecordPicker(BuildContext context) {
  final tracks = LibraryStore.instance.tracks; // newest uploads first
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: SwaramColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('Pick a song to sing',
                  style: TextStyle(
                      color: SwaramColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            for (final t in tracks)
              ListTile(
                leading: Icon(
                  t.isVideo ? Icons.movie_rounded : Icons.music_note_rounded,
                  color: trackColor(t),
                ),
                title: Text(t.title,
                    style: const TextStyle(color: SwaramColors.text)),
                subtitle: Text(
                  '${t.language} · ${t.localPath != null ? 'Uploaded' : t.uploader}',
                  style: const TextStyle(color: SwaramColors.muted),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  openRecordFor(context, t);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Mic button for top bars: sing the song that is on screen.
class SingButton extends StatelessWidget {
  final Track track;

  /// Runs before the record screen opens, e.g. to pause a playing video.
  final VoidCallback? beforeOpen;

  const SingButton({super.key, required this.track, this.beforeOpen});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sing this song',
      onPressed: () {
        beforeOpen?.call();
        openRecordFor(context, track);
      },
      icon: const Icon(Icons.mic_rounded, color: SwaramColors.teal, size: 26),
    );
  }
}
