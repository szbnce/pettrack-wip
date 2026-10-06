import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/widgets/highlight_card.dart';
import 'package:pettrack_app/widgets/skeleton_box.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows the recap card when the server has a highlight',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        HighlightCard(
          serverIp: 'http://127.0.0.1:8000',
          token: 't',
          fetcher: () async => {
            'date': '2026-10-06',
            'clip_count': 7,
            'filename': 'highlight_2026-10-06.mp4',
            'url': '/api/replays/highlight_2026-10-06.mp4?token=x',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today\'s recap'), findsOneWidget);
    expect(find.text('7 moments'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
  });

  testWidgets('hides itself for days without motion', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HighlightCard(
          serverIp: 'http://127.0.0.1:8000',
          token: 't',
          fetcher: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HighlightCard), findsOneWidget);
    expect(find.text('Today\'s recap'), findsNothing);
  });

  testWidgets('shows a skeleton while loading', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HighlightCard(
          serverIp: 'http://127.0.0.1:8000',
          token: 't',
          fetcher: () => Completer<Map<String, dynamic>?>().future,
        ),
      ),
    );

    expect(find.byType(SkeletonBox), findsOneWidget);
  });
}
