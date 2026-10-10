import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/models/insights_data.dart';
import 'package:pettrack_app/utils/insights_card.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('insightsCardTitle', () {
    test('names the pet on the card', () {
      expect(insightsCardTitle(l10n, 'Berci'), 'Berci on PetTrack');
    });

    test('an unnamed pet gets the generic line', () {
      expect(insightsCardTitle(l10n, ''), l10n.insightsCardGeneric);
    });

    test('whitespace is not a name', () {
      expect(insightsCardTitle(l10n, '   '), l10n.insightsCardGeneric);
    });

    test('the name is trimmed into the title', () {
      expect(insightsCardTitle(l10n, '  Berci  '), 'Berci on PetTrack');
    });
  });

  group('InsightsCard', () {
    // The card paints at a fixed 600 × 720 — give it a viewport that can
    // actually hold it instead of letting the test surface clamp it.
    Future<void> pumpCard(
      WidgetTester tester,
      InsightsData data,
      String petName,
    ) async {
      tester.view.physicalSize = const Size(640, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InsightsCard(
                l10n: l10n,
                data: data,
                rangeDays: 7,
                petName: petName,
                datesLabel: '4 – 10 Oct',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('paints the pet, the range and the week', (tester) async {
      final data = InsightsData(
        days: [
          for (var i = 0; i < 7; i++)
            InsightDay(
              date: _dayKey(DateTime(2026, 10, 4 + i)),
              clips: 3 + i,
              sounds: 1,
              events: 4 + i,
              activeSeconds: (20 + i * 15) * 60.0,
              zoneSeconds: const {'kitchen': 600},
            ),
        ],
      );

      await pumpCard(tester, data, 'Berci');

      expect(find.text('Berci on PetTrack'), findsOneWidget);
      expect(find.text('7 days · 4 – 10 Oct'), findsOneWidget);
      expect(find.text('on the move'), findsOneWidget);
      expect(find.textContaining('Most time in kitchen'), findsOneWidget);
      expect(find.text('Recorded on PetTrack'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a quiet week still shows the card, not a blank', (
      tester,
    ) async {
      final data = InsightsData(
        days: [
          for (var i = 0; i < 7; i++)
            InsightDay.quiet(_dayKey(DateTime(2026, 10, 4 + i))),
        ],
      );

      await pumpCard(tester, data, '');

      expect(find.text(l10n.insightsCardGeneric), findsOneWidget);
      // No top zone to name on a week with no zone time.
      expect(find.textContaining('Most time in'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long name does not push the card out of its frame', (
      tester,
    ) async {
      final data = InsightsData(
        days: [
          for (var i = 0; i < 7; i++)
            InsightDay(
              date: _dayKey(DateTime(2026, 10, 4 + i)),
              clips: 2,
              activeSeconds: 90 * 60.0,
              zoneSeconds: const {'the long corridor by the window': 600},
            ),
        ],
      );

      await pumpCard(tester, data, 'Berci the Third of His Name');

      expect(tester.takeException(), isNull);
    });
  });
}

String _dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
