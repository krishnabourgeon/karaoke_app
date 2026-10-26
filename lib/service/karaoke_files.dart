import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:karaoke_app/service/audio_mixier.dart';
import 'package:path_provider/path_provider.dart';

import 'package:karaoke_app/view/common_widgets/track.dart';

/// One message type for every karaoke error, so screens can show it directly.
class KaraokeException implements Exception {
  final String message;
  const KaraokeException(this.message);

  @override
  String toString() => message;
}

/// What the recorder plays: [audio] always, [video] only for video tracks.
class BackingTrack {
  final File audio;
  final File? video;
  const BackingTrack({required this.audio, this.video});
}

/// Where karaoke files live:
///   cache/karaoke/backing   downloaded or extracted backing tracks (safe to clear)
///   docs/karaoke/vocals     raw microphone takes
///   docs/karaoke/mixes      finished songs
class KaraokeFiles {
  KaraokeFiles._();
  static final KaraokeFiles instance = KaraokeFiles._();

  static const _playableAudio = {'.mp3', '.m4a', '.aac', '.wav'};

  Future<BackingTrack> prepareBacking(
    Track track, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _dir('backing', cache: true);
    final id = track.id.replaceAll(RegExp(r'[^\w-]'), '_');

    // 1. Get the source file on the device.
    final File source;
    if (track.localPath != null) {
      source = File(track.localPath!);
      if (!await source.exists()) {
        throw const KaraokeException(
            'This uploaded file is no longer on the device. Please upload it again.');
      }
    } else if (track.audioUrl.isNotEmpty) {
      final ext = _extension(track.audioUrl, fallback: track.isVideo ? '.mp4' : '.mp3');
      source = File('${dir.path}/${id}_source$ext');
      if (!await source.exists() || await source.length() == 0) {
        await _download(track.audioUrl, source, onProgress);
      }
    } else {
      throw const KaraokeException('This track has no audio.');
    }

    // 2. Videos and unusual formats → clean m4a, so every platform can play it
    //    and FFmpeg gets a predictable input.
    final ext = _extension(source.path, fallback: '');
    File audio = source;
    if (track.isVideo || !_playableAudio.contains(ext)) {
      audio = File('${dir.path}/${id}_audio.m4a');
      if (!await audio.exists() || await audio.length() == 0) {
        await AudioMixer.extractAudio(source.path, audio.path);
      }
    }

    return BackingTrack(audio: audio, video: track.isVideo ? source : null);
  }

  Future<String> newVocalsPath() async =>
      '${(await _dir('vocals')).path}/vocals_${_stamp()}.m4a';

  Future<String> newMixPath({required bool video}) async =>
      '${(await _dir('mixes')).path}/mix_${_stamp()}${video ? '.mp4' : '.m4a'}';

  Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> _download(
    String url,
    File target,
    void Function(double progress)? onProgress,
  ) async {
    final partial = File('${target.path}.part');
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) {
        throw KaraokeException('Could not download the track (HTTP ${response.statusCode}).');
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = partial.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call(received / total);
        }
      } finally {
        await sink.close();
      }
      await partial.rename(target.path);
    } on SocketException {
      throw const KaraokeException('No internet connection. Connect and try again.');
    } on http.ClientException {
      throw const KaraokeException('The download was interrupted. Please try again.');
    } finally {
      client.close();
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<Directory> _dir(String name, {bool cache = false}) async {
    final base = cache
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/karaoke/$name');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _extension(String pathOrUrl, {required String fallback}) {
    final segments = Uri.tryParse(pathOrUrl)?.pathSegments ?? const <String>[];
    final name = segments.isEmpty ? pathOrUrl : segments.last;
    final dot = name.lastIndexOf('.');
    return dot == -1 ? fallback : name.substring(dot).toLowerCase();
  }

  String _stamp() => DateTime.now().millisecondsSinceEpoch.toString();
}