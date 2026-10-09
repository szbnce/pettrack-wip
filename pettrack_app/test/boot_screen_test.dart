import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/main.dart';
import 'package:pettrack_app/screens/language_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('BootScreen routes without an artificial splash delay', (
    tester,
  ) async {
    // An unknown mode used to strand people on the spinner; now it starts
    // over — and it must get there immediately, not after a fixed pause.
    SharedPreferences.setMockInitialValues({'app_mode': 'bogus'});
    await tester.pumpWidget(_wrap(const BootScreen()));

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byType(BootScreen), findsNothing);
  });

  testWidgets('first launch goes to the language screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_wrap(const BootScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byType(BootScreen), findsNothing);
  });
}
