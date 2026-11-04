import 'package:flutter/material.dart';
import 'package:karaoke_app/model/get_songs_model.dart';
import 'package:karaoke_app/model/search_model.dart';
import 'swaram_common.dart';

class Track {
  final String id;
  final String title;
  final String language;
  final String duration; // display text for lists; the player reads the real length
  final String uploader;
  final int points;
  final String audioUrl; // streaming URL (API tracks)
  final String? localPath; // file on this device (uploaded tracks)
  final bool isVideo;
  final String genre;
  final String vibe;

  const Track({
    required this.id,
    required this.title,
    required this.language,
    required this.duration,
    required this.uploader,
    this.audioUrl = '',
    this.localPath,
    this.points = 5,
    this.isVideo = false,
    required this.genre,
    required this.vibe,
  });

  /// Builds a track from a song returned by the `songs` API.
  factory Track.fromSong(SongList s) => Track(
        id: s.id.toString(),
        title: s.title,
        language: s.language?.name ?? '',
        duration: s.durationLabel ?? _formatSeconds(s.duration),
        uploader: s.uploadedBy?.name ?? '',
        audioUrl: s.mediaUrl,
        isVideo: s.isVideo,
        genre: s.genre?.name ?? '',
        vibe: s.vibe?.name ?? '',
      );

  /// Builds a track from a song returned by the search API.
  factory Track.fromSearch(SongSearch s) => Track(
        id: s.id.toString(),
        title: s.title,
        language: s.language.name,
        duration: s.durationLabel ?? _formatSeconds(s.duration),
        uploader: s.uploadedBy.name,
        audioUrl: s.mediaUrl,
        isVideo: s.isVideo,
        genre: s.genre.name,
        vibe: s.vibe.name,
      );

  static String _formatSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Same track played from [path] (the extracted backing audio).
  Track withLocalPath(String path) => Track(
        id: id,
        title: title,
        language: language,
        duration: duration,
        uploader: uploader,
        audioUrl: audioUrl,
        localPath: path,
        points: points,
        isVideo: false, // the player always gets the extracted audio
        genre: genre,
        vibe: vibe,
      );

  /// Saved with a recording, so the take can find its backing track again.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'language': language,
        'duration': duration,
        'uploader': uploader,
        'points': points,
        'audioUrl': audioUrl,
        'localPath': localPath,
        'isVideo': isVideo,
        'genre': genre,
        'vibe': vibe,
      };

  factory Track.fromJson(Map<String, dynamic> m) => Track(
        id: m['id'] as String,
        title: m['title'] as String,
        language: m['language'] as String? ?? '',
        duration: m['duration'] as String? ?? '',
        uploader: m['uploader'] as String? ?? '',
        points: m['points'] as int? ?? 5,
        audioUrl: m['audioUrl'] as String? ?? '',
        localPath: m['localPath'] as String?,
        isVideo: m['isVideo'] as bool? ?? false,
        genre: m['genre'] as String? ?? '',
        vibe: m['vibe'] as String? ?? '',
      );

  Track withDuration(String value) => Track(
        id: id,
        title: title,
        language: language,
        duration: value,
        uploader: uploader,
        audioUrl: audioUrl,
        localPath: localPath,
        points: points,
        isVideo: isVideo,
        genre: genre,
        vibe: vibe,
      );
}

/// Same colour for the same track on every screen.
Color trackColor(Track track) {
  final sum = track.id.codeUnits.fold<int>(0, (a, b) => a + b);
  return [SwaramColors.amber, SwaramColors.pinkSoft, SwaramColors.teal][sum % 3];
}

