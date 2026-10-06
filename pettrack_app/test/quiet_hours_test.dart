import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/services/notification_service.dart';

/// Builds a [DateTime] on a fixed day at the given minutes after midnight.
DateTime _at(int minutes) => DateTime(2026, 10, 6, minutes ~/ 60, minutes % 60);

void main() {
  group('isWithinQuietHours', () {
    test('is always false when the feature is off', () {
      expect(isWithinQuietHours(_at(23 * 60 + 30), false, 23 * 60, 7 * 60),
          isFalse);
    });

    test('covers a window that wraps midnight', () {
      const from = 23 * 60; // 23:00
      const to = 7 * 60; // 07:00
      expect(isWithinQuietHours(_at(23 * 60), true, from, to), isTrue);
      expect(isWithinQuietHours(_at(23 * 60 + 59), true, from, to), isTrue);
      expect(isWithinQuietHours(_at(0), true, from, to), isTrue);
      expect(isWithinQuietHours(_at(6 * 60 + 59), true, from, to), isTrue);
      expect(isWithinQuietHours(_at(7 * 60), true, from, to), isFalse);
      expect(isWithinQuietHours(_at(22 * 60 + 59), true, from, to), isFalse);
      expect(isWithinQuietHours(_at(12 * 60), true, from, to), isFalse);
    });

    test('covers a same-day window', () {
      const from = 9 * 60; // 09:00
      const to = 17 * 60; // 17:00
      expect(isWithinQuietHours(_at(9 * 60), true, from, to), isTrue);
      expect(isWithinQuietHours(_at(16 * 60 + 59), true, from, to), isTrue);
      expect(isWithinQuietHours(_at(17 * 60), true, from, to), isFalse);
      expect(isWithinQuietHours(_at(8 * 60 + 59), true, from, to), isFalse);
    });

    test('treats from == to as an empty window', () {
      expect(isWithinQuietHours(_at(12 * 60), true, 12 * 60, 12 * 60), isFalse);
    });
  });
}
