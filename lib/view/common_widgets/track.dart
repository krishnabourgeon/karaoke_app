import 'package:flutter/material.dart';
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

// Test audio URLs. Replace with your real track URLs from the API.
const List<Track> kSampleTracks = [
  Track(
    id: 't1',
    title: 'Monsoon Evenings',
    language: 'Malayalam',
    duration: '4:12',
    uploader: '@anjali_k',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
  Track(
    id: 't2',
    title: 'Chai & Radio',
    language: 'Hindi',
    duration: '3:55',
    uploader: '@rohit.m',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
  Track(
    id: 't3',
    title: 'Marina Sunrise',
    language: 'Tamil',
    duration: '4:05',
    uploader: '@karthik_r',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
  Track(
    id: 't4',
    title: 'Kayal Moonlight',
    language: 'Malayalam',
    duration: '3:48',
    uploader: '@meera.s',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
  Track(
    id: 't5',
    title: 'Temple Bells at Dusk',
    language: 'Malayalam',
    duration: '4:30',
    uploader: '@arjun_n',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
  Track(
    id: 't6',
    title: 'Neon Highway',
    language: 'Telugu',
    duration: '3:40',
    uploader: '@sai_v',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
  Track(
    id: 't7',
    title: 'Rain on Tin Roofs',
    language: 'Tamil',
    duration: '4:22',
    uploader: '@divya_p',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
  Track(
    id: 't8',
    title: 'Midnight Ghazal',
    language: 'Hindi',
    duration: '5:02',
    uploader: '@imran.k',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    genre: 'Romantic',
    vibe: "90's vibe",
  ),
];