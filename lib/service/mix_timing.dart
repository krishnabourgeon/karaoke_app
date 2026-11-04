// /// Timing maths for the mixer. Pure functions, so they are unit tested.
// ///
// /// Two timelines are involved:
// ///   song time  – 0 is the first sample of the backing music.
// ///   vocal time – 0 is the first sample of the microphone file.
// ///
// /// The mic starts before the music ([musicOffsetMs]), so without any user
// /// change song time t is vocal time t + musicOffsetMs. A positive user
// /// [offsetMs] delays the vocals, i.e. song time t plays vocal time
// /// t + musicOffsetMs - offsetMs.
// library;

// /// Vocal time that plays at song time 0. Negative means the vocals must be
// /// padded with silence before they start.
// int vocalLeadMs({required int musicOffsetMs, required int offsetMs}) =>
//     musicOffsetMs - offsetMs;

// /// Length of the song when nothing is trimmed: the vocals (shifted) decide
// /// it, but it can never run past the backing music when that is known.
// int fullSongMs({
//   required int vocalsLengthMs,
//   required int musicOffsetMs,
//   required int offsetMs,
//   int? backingLengthMs,
// }) {
//   final lead = vocalLeadMs(musicOffsetMs: musicOffsetMs, offsetMs: offsetMs);
//   var end = vocalsLengthMs - lead;
//   if (backingLengthMs != null && backingLengthMs > 0 && end > backingLengthMs) {
//     end = backingLengthMs;
//   }
//   return end < 0 ? 0 : end;
// }

// /// What to read from each input to render song time [startMs]..[startMs+durationMs].
// class MixWindow {
//   final int startMs; // song time of the first output sample
//   final int durationMs;
//   final int musicSeekMs;
//   final int vocalSeekMs; // >= 0, where to start reading the mic file
//   final int vocalDelayMs; // >= 0, silence before the vocals start

//   const MixWindow({
//     required this.startMs,
//     required this.durationMs,
//     required this.musicSeekMs,
//     required this.vocalSeekMs,
//     required this.vocalDelayMs,
//   });

//   @override
//   String toString() =>
//       'MixWindow(start: $startMs, duration: $durationMs, music: $musicSeekMs, '
//       'vocalSeek: $vocalSeekMs, vocalDelay: $vocalDelayMs)';
// }

// /// Plans a render of song time [startMs] .. [endMs].
// ///
// /// With a negative lead (vocals delayed), nothing is cut from the vocals:
// /// silence is added instead, so a large negative offset never loses singing.
// MixWindow planWindow({
//   required int startMs,
//   required int endMs,
//   required int musicOffsetMs,
//   required int offsetMs,
// }) {
//   final start = startMs < 0 ? 0 : startMs;
//   final duration = endMs - start < 0 ? 0 : endMs - start;
//   final vocalStart =
//       start + vocalLeadMs(musicOffsetMs: musicOffsetMs, offsetMs: offsetMs);
//   return MixWindow(
//     startMs: start,
//     durationMs: duration,
//     musicSeekMs: start,
//     vocalSeekMs: vocalStart > 0 ? vocalStart : 0,
//     vocalDelayMs: vocalStart < 0 ? -vocalStart : 0,
//   );
// }

// /// The window for a full export after the user's start/end trims.
// MixWindow planExport({
//   required int vocalsLengthMs,
//   required int musicOffsetMs,
//   required int offsetMs,
//   required int trimStartMs,
//   required int trimEndMs,
//   int? backingLengthMs,
// }) {
//   final full = fullSongMs(
//     vocalsLengthMs: vocalsLengthMs,
//     musicOffsetMs: musicOffsetMs,
//     offsetMs: offsetMs,
//     backingLengthMs: backingLengthMs,
//   );
//   var start = trimStartMs.clamp(0, full);
//   var end = (full - trimEndMs).clamp(0, full);
//   if (end < start) end = start;
//   return planWindow(
//     startMs: start,
//     endMs: end,
//     musicOffsetMs: musicOffsetMs,
//     offsetMs: offsetMs,
//   );
// }

// /// FFmpeg wants seconds with millisecond precision.
// String ffSeconds(int ms) => (ms / 1000).toStringAsFixed(3);






/// Timing maths for the mixer. Pure functions, so they are unit tested.
///
/// Two timelines are involved:
///   song time  – 0 is the first sample of the backing music.
///   vocal time – 0 is the first sample of the microphone file.
///
/// The mic starts before the music ([musicOffsetMs]), so without any user
/// change song time t is vocal time t + musicOffsetMs. A positive user
/// [offsetMs] delays the vocals, i.e. song time t plays vocal time
/// t + musicOffsetMs - offsetMs.
library;

/// Vocal time that plays at song time 0. Negative means the vocals must be
/// padded with silence before they start.
int vocalLeadMs({required int musicOffsetMs, required int offsetMs}) =>
    musicOffsetMs - offsetMs;

/// Length of the song when nothing is trimmed: the vocals (shifted) decide
/// it, but it can never run past the backing music when that is known.
int fullSongMs({
  required int vocalsLengthMs,
  required int musicOffsetMs,
  required int offsetMs,
  int? backingLengthMs,
}) {
  final lead = vocalLeadMs(musicOffsetMs: musicOffsetMs, offsetMs: offsetMs);
  var end = vocalsLengthMs - lead;
  if (backingLengthMs != null && backingLengthMs > 0 && end > backingLengthMs) {
    end = backingLengthMs;
  }
  return end < 0 ? 0 : end;
}

/// What to read from each input to render song time [startMs]..[startMs+durationMs].
class MixWindow {
  final int startMs; // song time of the first output sample
  final int durationMs;
  final int musicSeekMs;
  final int vocalSeekMs; // >= 0, where to start reading the mic file
  final int vocalDelayMs; // >= 0, silence before the vocals start

  const MixWindow({
    required this.startMs,
    required this.durationMs,
    required this.musicSeekMs,
    required this.vocalSeekMs,
    required this.vocalDelayMs,
  });

  @override
  String toString() =>
      'MixWindow(start: $startMs, duration: $durationMs, music: $musicSeekMs, '
      'vocalSeek: $vocalSeekMs, vocalDelay: $vocalDelayMs)';
}

/// Plans a render of song time [startMs] .. [endMs].
///
/// With a negative lead (vocals delayed), nothing is cut from the vocals:
/// silence is added instead, so a large negative offset never loses singing.
MixWindow planWindow({
  required int startMs,
  required int endMs,
  required int musicOffsetMs,
  required int offsetMs,
}) {
  final start = startMs < 0 ? 0 : startMs;
  final duration = endMs - start < 0 ? 0 : endMs - start;
  final vocalStart =
      start + vocalLeadMs(musicOffsetMs: musicOffsetMs, offsetMs: offsetMs);
  return MixWindow(
    startMs: start,
    durationMs: duration,
    musicSeekMs: start,
    vocalSeekMs: vocalStart > 0 ? vocalStart : 0,
    vocalDelayMs: vocalStart < 0 ? -vocalStart : 0,
  );
}

/// The window for a full export after the user's start/end trims.
MixWindow planExport({
  required int vocalsLengthMs,
  required int musicOffsetMs,
  required int offsetMs,
  required int trimStartMs,
  required int trimEndMs,
  int? backingLengthMs,
}) {
  final full = fullSongMs(
    vocalsLengthMs: vocalsLengthMs,
    musicOffsetMs: musicOffsetMs,
    offsetMs: offsetMs,
    backingLengthMs: backingLengthMs,
  );
  var start = trimStartMs.clamp(0, full);
  var end = (full - trimEndMs).clamp(0, full);
  if (end < start) end = start;
  return planWindow(
    startMs: start,
    endMs: end,
    musicOffsetMs: musicOffsetMs,
    offsetMs: offsetMs,
  );
}

/// FFmpeg wants seconds with millisecond precision.
String ffSeconds(int ms) => (ms / 1000).toStringAsFixed(3);
