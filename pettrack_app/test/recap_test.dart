import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/recap.dart';

void main() {
  group('the night window', () {
    test('runs from yesterday 23:00 to today 06:00', () {
      final now = DateTime(2026, 10, 9, 10, 0);
      expect(nightStartFor(now), DateTime(2026, 10, 8, 23, 0));
      expect(nightEndFor(now), DateTime(2026, 10, 9, 6, 0));
    });
  });

  group('countNightEvents', () {
    final now = DateTime(2026, 10, 9, 10, 0);
    int at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

    test('counts what fell in the night', () {
      final ts = [
        at(DateTime(2026, 10, 8, 23, 30)),
        at(DateTime(2026, 10, 9, 2, 0)),
        at(DateTime(2026, 10, 9, 5, 59)),
      ];
      expect(countNightEvents(ts, now), 3);
    });

    test('ignores what falls outside it', () {
      final ts = [
        at(DateTime(2026, 10, 8, 22, 0)), // before the window
        at(DateTime(2026, 10, 9, 6, 0)), // at the end — exclusive
        at(DateTime(2026, 10, 9, 9, 0)), // this morning
      ];
      expect(countNightEvents(ts, now), 0);
    });

    test('says nothing while the night is still on', () {
      final beforeDawn = DateTime(2026, 10, 9, 3, 0);
      final ts = [at(DateTime(2026, 10, 9, 1, 0))];
      expect(countNightEvents(ts, beforeDawn), 0);
    });
  });

  group('shouldShowRecap', () {
    final morning = DateTime(2026, 10, 9, 10, 0);

    test('shows when the night had events and today is fresh', () {
      expect(
        shouldShowRecap(
          eventCount: 3,
          dismissedDay: '2026-10-08',
          now: morning,
        ),
        isTrue,
      );
    });

    test('stays quiet without events or after a dismissal', () {
      expect(
        shouldShowRecap(eventCount: 0, dismissedDay: null, now: morning),
        isFalse,
      );
      expect(
        shouldShowRecap(
          eventCount: 3,
          dismissedDay: '2026-10-09',
          now: morning,
        ),
        isFalse,
      );
    });

    test('stays quiet before 06:00 — the night is not over', () {
      expect(
        shouldShowRecap(
          eventCount: 3,
          dismissedDay: null,
          now: DateTime(2026, 10, 9, 4, 0),
        ),
        isFalse,
      );
    });
  });

  group('recapDayKey', () {
    test('is a sortable calendar day', () {
      expect(recapDayKey(DateTime(2026, 10, 9, 10, 0)), '2026-10-09');
    });
  });
}
