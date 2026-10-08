import '../l10n/app_localizations.dart';
import '../models/insights_data.dart';
import 'format_helpers.dart';

/// The plain text card behind Insights' share button: the headline numbers
/// of the selected range, one per line — readable in any chat app.
///
/// Kept as a pure function so the wording can be tested without a widget
/// tree. [InsightsData.daysInRange] pads the window with quiet days, so the
/// "today" line always has a day to report.
String buildInsightsShareText(
  AppLocalizations l10n,
  InsightsData data,
  int rangeDays,
) {
  final window = data.daysInRange(rangeDays);
  final today = window.last;
  final topZone = data.topZone(rangeDays);
  final totalSounds = window.fold<int>(0, (sum, d) => sum + d.sounds);

  final lines = <String>[
    l10n.shareInviteText,
    '',
    '${l10n.insightsTitle} · ${l10n.insightsRangeDays(rangeDays)}',
    '${l10n.insightsActiveToday}: '
        '${formatDurationSeconds(l10n, today.activeSeconds)} '
        '(${l10n.insightsClips(today.clips)})',
    '${l10n.insightsAvgPerDay}: '
        '${formatDurationSeconds(l10n, data.averageActiveSeconds(rangeDays))} '
        '(${l10n.insightsSounds(totalSounds)})',
  ];

  if (topZone == null) {
    lines.add(l10n.insightsZoneEmpty);
  } else {
    final topZoneSeconds = data
        .zoneTotals(rangeDays)
        .firstWhere((entry) => entry.key == topZone)
        .value;
    lines.add(
      '${l10n.insightsMostActiveZone}: $topZone '
      '· ${formatDurationSeconds(l10n, topZoneSeconds)}',
    );
  }
  return lines.join('\n');
}
