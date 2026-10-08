import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/models/insights_data.dart';
import 'package:pettrack_app/utils/insights_share.dart';

/// "YYYY-MM-DD" of the calendar day the test runs on — the share text's
/// window always ends on today.
String _todayKey() {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

void main() {
  group('buildInsightsShareText', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('opens with the invite and pins every headline number', () {
      final data = InsightsData(
        days: [
          InsightDay(
            date: _todayKey(),
            clips: 9,
            sounds: 2,
            activeSeconds: 240,
            zoneSeconds: const {'Kitchen': 2700, 'Sofa': 600},
          ),
        ],
      );

      expect(
        buildInsightsShareText(l10n, data, 7),
        'Look what my pet is doing!\n'
        '\n'
        'Activity insights · 7 days\n'
        'Active today: 4 min (9 motion clips)\n'
        'Per day (average): 34 s (2 sound events)\n'
        'Top zone: Kitchen · 45 min',
      );
    });

    test('a quiet range says so instead of naming a zone', () {
      final data = InsightsData(days: [InsightDay.quiet(_todayKey())]);
      final text = buildInsightsShareText(l10n, data, 7);

      expect(text, contains('Active today: 0 s (0 motion clips)'));
      expect(text, contains('No zone stays recorded in this range'));
      expect(text, isNot(contains('Top zone')));
    });
  });
}
