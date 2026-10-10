import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/screens/setup_wizard_screen.dart';

Widget _wrap() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const SetupWizardScreen(),
  );
}

void main() {
  testWidgets('the QR button leads, the manual form is the fallback', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    // Scan is the way most people pair — it comes before the address form,
    // with the "or" line between the two.
    final scan = find.byIcon(Icons.camera_alt);
    final orLine = find.text('OR');
    final ipField = find.widgetWithText(TextField, 'Server address');

    expect(scan, findsOneWidget);
    expect(orLine, findsOneWidget);
    expect(ipField, findsOneWidget);

    final scanY = tester.getCenter(scan).dy;
    final orY = tester.getCenter(orLine).dy;
    final ipY = tester.getCenter(ipField).dy;
    expect(scanY, lessThan(orY));
    expect(orY, lessThan(ipY));
  });

  testWidgets('the PIN button is live when the form is idle', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    final pinButton = find.widgetWithText(ElevatedButton, 'Submit PIN');
    expect(pinButton, findsOneWidget);

    // Idle: it is live, so a filled-in PIN can be sent.
    final button = tester.widget<ElevatedButton>(pinButton);
    expect(button.onPressed, isNotNull);
  });
}
