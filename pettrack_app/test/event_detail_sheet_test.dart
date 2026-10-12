import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/widgets/event_detail_sheet.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: Builder(builder: (context) => child)),
  );
}

void main() {
  Future<void> open(
    WidgetTester tester, {
    required Map<String, dynamic> event,
    VoidCallback? onWatchClip,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    // Deliberately not awaited: the future only resolves when the sheet is
    // closed, which is the thing the test is about to do.
    showEventDetailSheet(
      context: ctx,
      serverIp: 'http://127.0.0.1:9500',
      event: event,
      icon: Icons.meeting_room,
      color: Colors.blue,
      title: 'Berci entered the kitchen',
      subtitle: 'Movement was detected.',
      onWatchClip: onWatchClip ?? () {},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an event opens on its own words before the clip', (
    tester,
  ) async {
    await open(
      tester,
      event: {'timestamp': 1728000000, 'event_type': 'zone_enter'},
    );
    expect(find.text('Berci entered the kitchen'), findsOneWidget);
    expect(find.text('Movement was detected.'), findsOneWidget);
    expect(find.text('Watch the clip'), findsOneWidget);
  });

  testWidgets('the frame is offered, and the moment is named without one', (
    tester,
  ) async {
    await open(
      tester,
      event: {'timestamp': 1728000000, 'event_type': 'zone_enter'},
    );
    // No snapshot on this event: the sheet still says where and when, and
    // never shows a grey box pretending to be a frame. The when-chip always
    // separates day from time.
    expect(find.text('Movement was detected.'), findsOneWidget);
    expect(find.textContaining('·'), findsWidgets);
  });

  testWidgets('watching the clip is one tap from the sheet', (tester) async {
    var watched = false;
    await open(
      tester,
      event: {'timestamp': 1728000000, 'event_type': 'zone_enter'},
      onWatchClip: () => watched = true,
    );
    await tester.tap(find.text('Watch the clip'));
    await tester.pumpAndSettle();
    expect(watched, isTrue);
  });
}
