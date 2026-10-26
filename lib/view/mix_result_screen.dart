import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:karaoke_app/service/audio_mixier.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/library_store.dart';

/// Plays the finished song (music + vocals) and lets the user save or share it.
/// Audio mixes play through SwaramPlayer; video mixes through video_player.
class MixResultScreen extends StatefulWidget {
  final Track track;
  final MixOutput output;

  const MixResultScreen({super.key, required this.track, required this.output});

  static Route<void> route({required Track track, required MixOutput output}) =>
      MaterialPageRoute<void>(
          builder: (_) => MixResultScreen(track: track, output: output));

  @override
  State<MixResultScreen> createState() => _MixResultScreenState();
}

class _MixResultScreenState extends State<MixResultScreen> {
  final SwaramPlayer _player = SwaramPlayer.instance;
  VideoPlayerController? _video;
  bool _busy = false;
  bool _savedToLibrary = false;

  String get _path => widget.output.path;
  bool get _isVideo => widget.output.isVideo;

  late final Track _song = Track(
    id: 'mix_${_path.hashCode}',
    title: '${widget.track.title} (My cover)',
    language: widget.track.language,
    duration: '',
    uploader: LibraryStore.instance.uploaderName,
    localPath: _path,
    isVideo: _isVideo,
    genre: widget.track.genre,
    vibe: widget.track.vibe,
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!await File(_path).exists()) {
      _snack('The finished song is missing. Please mix again.');
      return;
    }
    if (_isVideo) {
      await _player.pause();
      final video = VideoPlayerController.file(File(_path));
      await video.initialize();
      if (!mounted) {
        await video.dispose();
        return;
      }
      video.addListener(_onVideoTick);
      setState(() => _video = video);
      await video.play();
    } else {
      await _player.playFile(_song);
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    if (!_isVideo) unawaited(_player.pause());
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final video = _video;
    if (video != null) {
      video.value.isPlaying ? await video.pause() : await video.play();
      return;
    }
    if (_player.currentTrack.value?.localPath == _path) {
      await _player.togglePlay();
    } else {
      await _player.playFile(_song);
    }
  }

  Future<void> _saveToLibrary() async {
    if (_savedToLibrary) return;
    setState(() => _busy = true);
    try {
      await LibraryStore.instance.addUpload(
        sourcePath: _path,
        title: _song.title,
        language: _song.language,
        isVideo: _isVideo,
        genre: _song.genre,
        vibe: _song.vibe,
      );
      _savedToLibrary = true;
      _snack('Saved to your library.');
    } catch (_) {
      _snack('Could not save to your library.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToDevice() async {
    setState(() => _busy = true);
    try {
      final name = _song.title.replaceAll(RegExp(r'[^\w\s()-]'), '').trim();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save your song',
        fileName: '$name${_isVideo ? '.mp4' : '.m4a'}',
        bytes: await File(_path).readAsBytes(),
      );
      if (saved != null) _snack('Song saved.');
    } catch (_) {
      _snack('Could not save the file.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(_path, mimeType: _isVideo ? 'video/mp4' : 'audio/mp4')],
        text: 'Listen to my cover of ${widget.track.title} on Swaram!',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (_) {
      _snack('Could not open the share sheet.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: SwaramColors.card,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(color: SwaramColors.text)),
      ));
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = trackColor(widget.track);
    final video = _video;
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      appBar: AppBar(
        backgroundColor: SwaramColors.bg,
        foregroundColor: SwaramColors.text,
        title: const Text('Your song'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: video != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: video.value.aspectRatio,
                            child: VideoPlayer(video),
                          ),
                        )
                      : Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(Icons.graphic_eq_rounded,
                              size: 90, color: color),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _song.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SwaramColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text('${widget.track.language} · music + your voice',
                  style: const TextStyle(color: SwaramColors.muted)),
              const SizedBox(height: 12),
              video != null ? _videoControls(video) : _audioControls(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy || _savedToLibrary ? null : _saveToLibrary,
                      icon: Icon(_savedToLibrary
                          ? Icons.check_rounded
                          : Icons.library_add_rounded),
                      label: Text(_savedToLibrary ? 'In library' : 'Library'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _saveToDevice,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audioControls() {
    return StreamBuilder<PlayerState>(
      stream: _player.stateStream,
      builder: (context, stateSnap) {
        final mine = _player.currentTrack.value?.localPath == _path;
        final s = stateSnap.data;
        final playing = mine &&
            (s?.playing ?? false) &&
            s?.processingState != ProcessingState.completed;
        return Column(
          children: [
            StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, durSnap) {
                final total =
                    mine ? (durSnap.data ?? Duration.zero) : Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, posSnap) {
                    final pos =
                        mine ? (posSnap.data ?? Duration.zero) : Duration.zero;
                    final max = total.inMilliseconds.toDouble();
                    return Column(
                      children: [
                        Slider(
                          value: max == 0
                              ? 0
                              : pos.inMilliseconds
                                  .clamp(0, max.toInt())
                                  .toDouble(),
                          max: max == 0 ? 1 : max,
                          activeColor: SwaramColors.amber,
                          onChanged: max == 0
                              ? null
                              : (v) => _player
                                  .seek(Duration(milliseconds: v.round())),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos),
                                style:
                                    const TextStyle(color: SwaramColors.muted)),
                            Text(_fmt(total),
                                style:
                                    const TextStyle(color: SwaramColors.muted)),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            _playButton(playing),
          ],
        );
      },
    );
  }

  Widget _videoControls(VideoPlayerController video) {
    return Column(
      children: [
        VideoProgressIndicator(
          video,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          colors: const VideoProgressColors(playedColor: SwaramColors.amber),
        ),
        _playButton(video.value.isPlaying),
      ],
    );
  }

  Widget _playButton(bool playing) {
    return IconButton.filled(
      iconSize: 40,
      style: IconButton.styleFrom(
        backgroundColor: SwaramColors.amber,
        foregroundColor: SwaramColors.onAmber,
        fixedSize: const Size(72, 72),
      ),
      onPressed: _togglePlay,
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}
