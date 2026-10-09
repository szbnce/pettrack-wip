/// Alert snooze ("I'm home"): pure helpers, exported for tests.
///
/// Snoozing silences this phone's alert notifications for a while —
/// recording keeps running, arming is what decides what gets recorded.
library;

/// Presets for how long alerts stay quiet.
const snoozePreset30m = '30m';
const snoozePreset1h = '1h';
const snoozePresetTonight = 'tonight';

/// The moment a [preset] snooze ends, as ms since epoch.
///
/// "Tonight" runs until 23:00 — the hour quiet hours usually take over —
/// and rolls to the next day when the day is already over.
int snoozeUntilMillis(String preset, DateTime now) {
  switch (preset) {
    case snoozePreset30m:
      return now.add(const Duration(minutes: 30)).millisecondsSinceEpoch;
    case snoozePreset1h:
      return now.add(const Duration(hours: 1)).millisecondsSinceEpoch;
    case snoozePresetTonight:
      final tonight = DateTime(now.year, now.month, now.day, 23);
      final until = tonight.isAfter(now)
          ? tonight
          : tonight.add(const Duration(days: 1));
      return until.millisecondsSinceEpoch;
    default:
      return now.millisecondsSinceEpoch;
  }
}

/// True while the snooze has not run out yet.
bool isSnoozed(int nowMillis, int? untilMillis) =>
    untilMillis != null && untilMillis > nowMillis;
