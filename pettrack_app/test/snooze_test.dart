import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/snooze.dart';

void main() {
  group('snoozeUntilMillis', () {
    final now = DateTime(2026, 10, 9, 14, 0);

    test('the short presets are relative to now', () {
      expect(
        DateTime.fromMillisecondsSinceEpoch(
          snoozeUntilMillis(snoozePreset30m, now),
        ),
        now.add(const Duration(minutes: 30)),
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(
          snoozeUntilMillis(snoozePreset1h, now),
        ),
        now.add(const Duration(hours: 1)),
      );
    });

    test('tonight runs until 23:00 of the same day', () {
      expect(
        DateTime.fromMillisecondsSinceEpoch(
          snoozeUntilMillis(snoozePresetTonight, now),
        ),
        DateTime(2026, 10, 9, 23, 0),
      );
    });

    test('tonight after 23:00 rolls to the next day', () {
      final late = DateTime(2026, 10, 9, 23, 30);
      expect(
        DateTime.fromMillisecondsSinceEpoch(
          snoozeUntilMillis(snoozePresetTonight, late),
        ),
        DateTime(2026, 10, 10, 23, 0),
      );
    });

    test('an unknown preset ends immediately', () {
      expect(snoozeUntilMillis('nonsense', now), now.millisecondsSinceEpoch);
    });
  });

  group('isSnoozed', () {
    test('only while the deadline has not passed', () {
      const now = 1000;
      expect(isSnoozed(now, null), isFalse);
      expect(isSnoozed(now, 999), isFalse);
      expect(isSnoozed(now, now), isFalse);
      expect(isSnoozed(now, 1001), isTrue);
    });
  });
}
