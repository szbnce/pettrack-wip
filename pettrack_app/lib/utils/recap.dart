/// Morning recap: the "last night" window and the once-a-day banner rule.
library;

/// The night window: yesterday 23:00 → today 06:00. Events in it are
/// "while you slept" no matter when during the day you open the app.
DateTime nightStartFor(DateTime now) =>
    DateTime(now.year, now.month, now.day).subtract(const Duration(hours: 1));

DateTime nightEndFor(DateTime now) => DateTime(now.year, now.month, now.day, 6);

/// `yyyy-MM-dd` — the day a dismissed banner stays quiet.
String recapDayKey(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

/// How many of [timestampsSeconds] fell inside the night window.
/// Before 06:00 the night is still on, so the recap counts nothing yet.
int countNightEvents(Iterable<num> timestampsSeconds, DateTime now) {
  if (now.isBefore(nightEndFor(now))) return 0;
  final start = nightStartFor(now);
  final end = nightEndFor(now);
  var count = 0;
  for (final ts in timestampsSeconds) {
    final at = DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt());
    if (!at.isBefore(start) && at.isBefore(end)) count++;
  }
  return count;
}

/// The banner earns its place once per day: there was something in the
/// night, the night is over, and today's banner has not been dismissed.
bool shouldShowRecap({
  required int eventCount,
  required String? dismissedDay,
  required DateTime now,
}) {
  if (eventCount <= 0) return false;
  if (now.isBefore(nightEndFor(now))) return false;
  return dismissedDay != recapDayKey(now);
}
