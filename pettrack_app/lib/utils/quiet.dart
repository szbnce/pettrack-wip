/// The calm line under the feed: the house has been still.
///
/// Silence is the happy path of a pet camera — saying so, once in a while,
/// is more reassuring than an empty list and a shrug.
library;

/// After this much stillness the feed says something.
const quietAfter = Duration(minutes: 30);

/// How long the house has been still, or null when there is no baseline
/// yet (first run, or the clock is somehow behind the last event).
Duration? quietFor(int? lastEventSeconds, DateTime now) {
  if (lastEventSeconds == null) return null;
  final d = now.difference(
    DateTime.fromMillisecondsSinceEpoch(lastEventSeconds * 1000),
  );
  return d.isNegative ? null : d;
}

/// Whether the stillness has lasted long enough to be worth a line of text.
bool shouldShowQuiet(
  int? lastEventSeconds,
  DateTime now, {
  Duration after = quietAfter,
}) {
  final d = quietFor(lastEventSeconds, now);
  return d != null && d >= after;
}
