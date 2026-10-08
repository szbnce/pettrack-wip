/// Arming: when the camera actually watches.
///
/// The server's three modes, mirrored: "on" always records, "off" never
/// does, "schedule" follows the weekly windows below. The JSON shape is
/// exactly what /api/arming exchanges.
const String armingModeOn = 'on';
const String armingModeSchedule = 'schedule';
const String armingModeOff = 'off';

/// One weekly window. Days are ISO weekdays (1 = Monday .. 7 = Sunday);
/// times are minutes after midnight. `from == to` is an empty window and
/// `from > to` wraps midnight — the tail after midnight belongs to the
/// window's start day ("Monday night" runs into Tuesday morning).
class ArmingWindow {
  ArmingWindow({
    required Set<int> days,
    required this.fromMin,
    required this.toMin,
  }) : assert(fromMin >= 0 && fromMin < 1440),
       assert(toMin >= 0 && toMin < 1440),
       days = Set.unmodifiable({...days}.where((d) => d >= 1 && d <= 7));

  /// The sensible default for "only watch while I'm at work".
  ArmingWindow.workweek()
    : this(days: const {1, 2, 3, 4, 5}, fromMin: 9 * 60, toMin: 17 * 60);

  final Set<int> days;
  final int fromMin;
  final int toMin;

  factory ArmingWindow.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    return ArmingWindow(
      days: {
        if (rawDays is List) ...rawDays.whereType<num>().map((d) => d.toInt()),
      },
      fromMin: _asMinute(json['from_min']),
      toMin: _asMinute(json['to_min']),
    );
  }

  Map<String, dynamic> toJson() => {
    'days': (days.toList()..sort()),
    'from_min': fromMin,
    'to_min': toMin,
  };

  ArmingWindow copyWith({Set<int>? days, int? fromMin, int? toMin}) {
    return ArmingWindow(
      days: days ?? this.days,
      fromMin: fromMin ?? this.fromMin,
      toMin: toMin ?? this.toMin,
    );
  }

  /// Day toggle that never empties the window — a window with no days is
  /// not a window.
  ArmingWindow togglingDay(int day) {
    final next = {...days};
    if (!next.remove(day)) next.add(day);
    if (next.isEmpty) return this;
    return copyWith(days: next);
  }

  static int _asMinute(Object? value) => value is num ? value.toInt() : 0;
}

/// The schedule list off the wire; junk entries are dropped, not crashed on.
List<ArmingWindow> parseArmingSchedule(Object? raw) {
  if (raw is! List) return [];
  final windows = <ArmingWindow>[];
  for (final entry in raw.whereType<Map>()) {
    final window = ArmingWindow.fromJson(Map<String, dynamic>.from(entry));
    // A window with no usable day is not a window — the server drops these
    // too, so the app must never invent a day for one.
    if (window.days.isNotEmpty) windows.add(window);
  }
  return windows;
}
