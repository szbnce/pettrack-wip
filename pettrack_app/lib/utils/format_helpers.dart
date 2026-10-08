import 'package:pettrack_app/l10n/app_localizations.dart';

/// Whole-unit duration for charts and status lines: "2 h 15 min", "45 min",
/// "20 s". The strings live with the insights strings in the .arb files.
String formatDurationSeconds(AppLocalizations l10n, double seconds) {
  final total = seconds.round();
  if (total < 60) return l10n.insightsDurationS(total);
  final minutes = total ~/ 60;
  if (minutes < 60) return l10n.insightsDurationM(minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0
      ? l10n.insightsDurationH(hours)
      : l10n.insightsDurationHm(hours, rest);
}

/// Byte sizes as humans read them: "512 B", "1.0 KB", "1.5 GB".
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  do {
    value /= 1024;
    unit++;
  } while (value >= 1024 && unit < units.length - 1);
  final text = value >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
