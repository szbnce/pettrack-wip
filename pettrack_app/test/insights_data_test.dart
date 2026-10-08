import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/models/insights_data.dart';

InsightDay day(
  String date, {
  double active = 0,
  int clips = 0,
  int sounds = 0,
  Map<String, double> zones = const {},
}) => InsightDay(
  date: date,
  activeSeconds: active,
  clips: clips,
  sounds: sounds,
  zoneSeconds: zones,
);

void main() {
  final today = DateTime(2026, 10, 8);

  group('daysInRange', () {
    test('fills quiet days so the chart has one column per day', () {
      final data = InsightsData(
        days: [day('2026-10-03', active: 60), day('2026-10-08', active: 120)],
      );
      final window = data.daysInRange(7, today: today);

      expect(window.length, 7);
      expect(window.first.date, '2026-10-02');
      expect(window.last.date, '2026-10-08');
      expect(
        [for (final d in window) d.activeSeconds],
        [0, 60, 0, 0, 0, 0, 120],
      );
    });

    test('drops server days that fall outside the window', () {
      final data = InsightsData(
        days: [day('2026-10-01', active: 60), day('2026-10-08', active: 30)],
      );
      final window = data.daysInRange(7, today: today);

      expect(window.any((d) => d.date == '2026-10-01'), isFalse);
    });

    test('parses the server payload', () {
      final data = InsightsData.fromJson({
        'days': [
          {
            'date': '2026-10-08',
            'clips': 3,
            'sounds': 1,
            'events': 4,
            'active_seconds': 90.0,
            'zone_seconds': {'kitchen': 120.0},
          },
        ],
      });

      final parsed = data.days.single;
      expect(parsed.clips, 3);
      expect(parsed.sounds, 1);
      expect(parsed.activeSeconds, 90.0);
      expect(parsed.activeMinutes, 2); // rounded to whole minutes
      expect(parsed.zoneSeconds, {'kitchen': 120.0});
    });
  });

  group('aggregates', () {
    test('the average counts quiet days, not just busy ones', () {
      final data = InsightsData(days: [day('2026-10-08', active: 300)]);
      // 300 s of motion spread over a 7-day window.
      expect(
        data.averageActiveSeconds(7, today: today),
        closeTo(300 / 7, 0.001),
      );
    });

    test('zone totals are summed and sorted, biggest first', () {
      final data = InsightsData(
        days: [
          day('2026-10-07', zones: {'kitchen': 60, 'sofa': 30}),
          day('2026-10-08', zones: {'kitchen': 45, 'bed': 90}),
        ],
      );
      final totals = data.zoneTotals(7, today: today);

      expect(totals.map((e) => e.key).toList(), ['kitchen', 'bed', 'sofa']);
      expect(totals.map((e) => e.value).toList(), [105.0, 90.0, 30.0]);
      expect(data.topZone(7, today: today), 'kitchen');
    });

    test('there is no top zone when nothing is recorded', () {
      const data = InsightsData(days: []);
      expect(data.topZone(7, today: today), isNull);
      expect(data.zoneTotals(7, today: today), isEmpty);
    });
  });

  group('demo data', () {
    test('covers the requested range with some activity every day', () {
      final data = InsightsData.demo(
        rangeDays: 14,
        zoneNames: ['kitchen', 'sofa'],
        now: today,
      );
      final window = data.daysInRange(14, today: today);

      expect(window.length, 14);
      expect(window.every((d) => d.activeSeconds > 0), isTrue);
      expect(data.topZone(14, today: today), anyOf('kitchen', 'sofa'));
    });
  });
}
