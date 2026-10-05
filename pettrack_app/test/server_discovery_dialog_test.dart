import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/widgets/server_discovery_dialog.dart';

Widget _wrap(Widget child, {Locale? locale}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('discovery button is localized', (tester) async {
    await tester.pumpWidget(
      _wrap(ServerDiscoveryButton(onSelected: (_) {}), locale: const Locale('hu')),
    );
    expect(find.text('Szerver keresése a hálózaton'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_find), findsOneWidget);
  });

  testWidgets('dialog falls back to manual entry where NSD is missing', (
    tester,
  ) async {
    // No NSD platform implementation in tests -> the dialog must degrade to
    // the "enter the address manually" message instead of spinning forever.
    String? selected;
    await tester.pumpWidget(
      _wrap(
        ServerDiscoveryButton(onSelected: (a) => selected = a),
        locale: const Locale('en'),
      ),
    );

    await tester.tap(find.byType(ServerDiscoveryButton));
    await tester.pump(); // open dialog
    // The dialog gives up on a hung lookup after 3s and shows manual entry.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(
      find.text(
        'Automatic discovery is not available on this device. '
        'Enter the server address manually.',
      ),
      findsOneWidget,
    );
    expect(selected, isNull);
  });
}
