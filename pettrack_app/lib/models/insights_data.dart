import 'dart:math';

/// One calendar day of activity, as bucketed by the server.
class InsightDay {
  final String date; // "YYYY-MM-DD", server-local calendar
  final int clips;
  final int sounds;
  final int events;
  final double activeSeconds;
  final Map<String, double> zoneSeconds;

  const InsightDay({
    required this.date,
    this.clips = 0,
    this.sounds = 0,
    this.events = 0,
    this.activeSeconds = 0,
    this.zoneSeconds = const {},
  });

  /// A day with no activity at all — used to pad a range so the charts
  /// never skip a quiet stretch.
  InsightDay.quiet(this.date)
    : clips = 0,
      sounds = 0,
      events = 0,
      activeSeconds = 0,
      zoneSeconds = const {};

  factory InsightDay.fromJson(Map<String, dynamic> json) {
    final zones = <String, double>{};
    final raw = json['zone_seconds'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is num) zones['$key'] = value.toDouble();
      });
    }
    return InsightDay(
      date: json['date'] as String,
      clips: (json['clips'] as num? ?? 0).toInt(),
      sounds: (json['sounds'] as num? ?? 0).toInt(),
      events: (json['events'] as num? ?? 0).toInt(),
      activeSeconds: (json['active_seconds'] as num? ?? 0).toDouble(),
      zoneSeconds: zones,
    );
  }

  int get activeMinutes => (activeSeconds / 60).round();
}

/// Activity insights over a time range: per-day buckets plus the zone totals.
class InsightsData {
  final List<InsightDay> days;

  const InsightsData({required this.days});

  factory InsightsData.fromJson(Map<String, dynamic> json) {
    final raw = json['days'];
    final days = <InsightDay>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) days.add(InsightDay.fromJson(entry));
      }
    }
    return InsightsData(days: days);
  }

  static String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Exactly [rangeDays] days, oldest first, ending on [today] (default: now),
  /// with quiet days filled in so the column chart never skips a gap.
  /// Server days that fall outside the window are dropped — the server's
  /// window is a rolling "N × 24 h", which can reach one day further back.
  List<InsightDay> daysInRange(int rangeDays, {DateTime? today}) {
    final end = _dateOnly(today ?? DateTime.now());
    final wanted = [
      for (var i = rangeDays - 1; i >= 0; i--)
        _key(end.subtract(Duration(days: i))),
    ];
    final byKey = {for (final day in days) day.date: day};
    return [for (final key in wanted) byKey[key] ?? InsightDay.quiet(key)];
  }

  /// Seconds of motion on the average day of the range (quiet days included).
  double averageActiveSeconds(int rangeDays, {DateTime? today}) {
    final window = daysInRange(rangeDays, today: today);
    final total = window.fold<double>(0, (sum, d) => sum + d.activeSeconds);
    return total / rangeDays;
  }

  /// Seconds spent per zone across the range, largest first.
  List<MapEntry<String, double>> zoneTotals(int rangeDays, {DateTime? today}) {
    final totals = <String, double>{};
    for (final day in daysInRange(rangeDays, today: today)) {
      day.zoneSeconds.forEach((zone, seconds) {
        totals[zone] = (totals[zone] ?? 0) + seconds;
      });
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// The zone with the most seconds in the range, or null when none recorded.
  String? topZone(int rangeDays, {DateTime? today}) {
    final totals = zoneTotals(rangeDays, today: today);
    return totals.isEmpty ? null : totals.first.key;
  }

  static DateTime _dateOnly(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  /// Synthetic data for demo mode: a plausible week-shaped activity curve
  /// with a fixed seed, so the demo looks the same on every run.
  factory InsightsData.demo({
    required int rangeDays,
    required List<String> zoneNames,
    DateTime? now,
  }) {
    final random = Random(42);
    final end = _dateOnly(now ?? DateTime.now());
    final days = <InsightDay>[];
    for (var i = rangeDays - 1; i >= 0; i--) {
      final day = end.subtract(Duration(days: i));
      final key = _key(day);
      // Weekends run a little calmer, mid-week the busiest — a pet's week
      // is mostly rhythm, not randomness.
      final weekend = day.weekday >= 6;
      final clips = weekend ? 4 + random.nextInt(8) : 8 + random.nextInt(16);
      final sounds = random.nextInt(4);
      final zones = <String, double>{};
      for (final name in zoneNames) {
        if (random.nextBool()) continue;
        zones[name] = (15 + random.nextInt(90)) * 60.0;
      }
      days.add(
        InsightDay(
          date: key,
          clips: clips,
          sounds: sounds,
          events: clips + sounds + random.nextInt(3),
          activeSeconds: clips * 30.0,
          zoneSeconds: zones,
        ),
      );
    }
    return InsightsData(days: days);
  }
}
