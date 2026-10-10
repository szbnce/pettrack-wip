/// Event → evidence: pure helpers for jumping from a feed row or an alert
/// notification to the footage of that moment.
///
/// Clips are motion-triggered and about half a minute long, so "the clip of
/// a moment" is the one that contains it — or the nearest one just outside.
/// Two minutes is the reach: further away and a clip is no longer evidence
/// of that moment.
const int defaultReachSeconds = 2 * 60;

/// The clip nearest to [momentSeconds], or null when no clip's timestamp
/// sits within [reachSeconds] of it (or the list has no usable entries).
Map<String, dynamic>? nearestClipTo(
  List<dynamic> replays,
  int momentSeconds, {
  int reachSeconds = defaultReachSeconds,
}) {
  Map<String, dynamic>? nearest;
  var best = reachSeconds + 1;
  for (final replay in replays) {
    final ts = (replay as Map)['timestamp'] as num?;
    if (ts == null) continue;
    final delta = (ts.toInt() - momentSeconds).abs();
    if (delta <= reachSeconds && delta < best) {
      best = delta;
      nearest = Map<String, dynamic>.from(replay);
    }
  }
  return nearest;
}

/// How far into [clip] the [moment] falls, so the player can start there.
///
/// The clip's timestamp is when recording began (the server reads it from
/// the filename). A moment before the first frame starts at zero; one after
/// the last is left to the player to clamp against the real duration.
Duration seekOffsetIn(Map<String, dynamic> clip, int momentSeconds) {
  final start = (clip['timestamp'] as num?)?.toInt();
  if (start == null) return Duration.zero;
  final offset = momentSeconds - start;
  return offset <= 0 ? Duration.zero : Duration(seconds: offset);
}

/// Notification payload marker for alerts that have footage behind them.
const String evidencePayloadPrefix = 'evidence:';

/// Build the payload a tap-on-alert carries: the event's unix seconds.
String evidencePayload(int timestampSeconds) =>
    '$evidencePayloadPrefix$timestampSeconds';

/// The event's unix seconds from a notification payload, or null when the
/// payload is not an evidence payload.
int? parseEvidencePayload(String payload) {
  if (!payload.startsWith(evidencePayloadPrefix)) return null;
  return int.tryParse(payload.substring(evidencePayloadPrefix.length));
}
