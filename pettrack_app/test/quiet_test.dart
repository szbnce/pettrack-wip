import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/quiet.dart';

void main() {
  final now = DateTime(2026, 10, 9, 12, 0, 0);

  group('quietFor', () {
    test('counts from the last event to now', () {
      final last = now.subtract(const Duration(hours: 2, minutes: 15));
      final d = quietFor(last.millisecondsSinceEpoch ~/ 1000, now);
      expect(d, const Duration(hours: 2, minutes: 15));
    });

    test('no baseline, no stillness to report', () {
      expect(quietFor(null, now), isNull);
    });

    test('a clock behind the last event is not "quiet"', () {
      final last = now.add(const Duration(minutes: 5));
      expect(quietFor(last.millisecondsSinceEpoch ~/ 1000, now), isNull);
    });
  });

  group('shouldShowQuiet', () {
    test('stays mum for the first half hour', () {
      final last = now.subtract(const Duration(minutes: 29));
      expect(
        shouldShowQuiet(last.millisecondsSinceEpoch ~/ 1000, now),
        isFalse,
      );
    });

    test('speaks up at the half-hour mark', () {
      final last = now.subtract(const Duration(minutes: 30));
      expect(shouldShowQuiet(last.millisecondsSinceEpoch ~/ 1000, now), isTrue);
    });

    test('a custom threshold is honoured', () {
      final last = now.subtract(const Duration(minutes: 5));
      expect(
        shouldShowQuiet(
          last.millisecondsSinceEpoch ~/ 1000,
          now,
          after: const Duration(minutes: 5),
        ),
        isTrue,
      );
    });
  });
}
