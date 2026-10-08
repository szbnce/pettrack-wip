import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/arming.dart';

void main() {
  group('ArmingWindow', () {
    test('JSON round-trips and always sends sorted ISO days', () {
      final window = ArmingWindow(
        days: {7, 3, 1},
        fromMin: 9 * 60,
        toMin: 17 * 60,
      );
      expect(window.toJson(), {
        'days': [1, 3, 7],
        'from_min': 540,
        'to_min': 1020,
      });
      final back = ArmingWindow.fromJson(window.toJson());
      expect(back.days, {1, 3, 7});
      expect(back.fromMin, 540);
      expect(back.toMin, 1020);
    });

    test('junk on the wire is dropped, not crashed on', () {
      final window = ArmingWindow.fromJson({
        'days': [0, 2, 9, 'x', 4.0, true],
        'from_min': 'noon',
        'to_min': 120,
      });
      expect(window.days, {2, 4});
      expect(window.fromMin, 0);
      expect(window.toMin, 120);
    });

    test('toggling days keeps the window valid', () {
      final week = ArmingWindow.workweek();
      expect(week.togglingDay(6).days, {1, 2, 3, 4, 5, 6});
      expect(week.togglingDay(1).days, {2, 3, 4, 5});
      // The last day cannot go — a window without days is not a window.
      final single = ArmingWindow(days: {3}, fromMin: 0, toMin: 60);
      expect(single.togglingDay(3).days, {3});
    });

    test('the workweek default is the away-hours window', () {
      final week = ArmingWindow.workweek();
      expect(week.days, {1, 2, 3, 4, 5});
      expect(week.fromMin, 9 * 60);
      expect(week.toMin, 17 * 60);
    });
  });

  group('parseArmingSchedule', () {
    test('drops junk entries and keeps the rest', () {
      final windows = parseArmingSchedule([
        'junk',
        null,
        {
          'days': [1],
          'from_min': 60,
          'to_min': 120,
        },
        42,
      ]);
      expect(windows.length, 1);
      expect(windows.first.days, {1});
      expect(windows.first.fromMin, 60);
    });

    test('anything but a list is an empty schedule', () {
      expect(parseArmingSchedule(null), isEmpty);
      expect(parseArmingSchedule('junk'), isEmpty);
    });
  });
}
