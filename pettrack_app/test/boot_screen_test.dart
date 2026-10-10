import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/main.dart';
import 'package:pettrack_app/screens/language_screen.dart';
import 'package:pettrack_app/screens/main_navigation.dart';
import 'package:pettrack_app/screens/server_recovery_screen.dart';
import 'package:pettrack_app/screens/setup_wizard_screen.dart';
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

  testWidgets('a pairing that never finished goes back to the wizard', (
    tester,
  ) async {
    // Pairing alone is not setup. A phone that reached the secret but never
    // named a pet used to land on an empty dashboard with no way forward;
    // the wizard is where that belongs — and it resumes from there.
    SharedPreferences.setMockInitialValues({
      'app_mode': 'client',
      'server_ip': 'http://192.168.1.10:8000',
      'secret_token': 's3cret',
    });
    await tester.pumpWidget(_wrap(const BootScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(SetupWizardScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(find.byType(BootScreen), findsNothing);
  });

  testWidgets(
    'a set-up phone that cannot reach its server is not told to pair again',
    (tester) async {
      // The session lapsed and the network is down. The wizard would look
      // like the setup was lost; this is a network problem, and it says so.
      SharedPreferences.setMockInitialValues({
        'app_mode': 'client',
        'server_ip': 'http://192.168.1.10:8000',
        'secret_token': 's3cret',
        'pet_name': 'Berci',
        'is_setup_completed': true,
      });
      await tester.pumpWidget(_wrap(const BootScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(ServerRecoveryScreen), findsOneWidget);
      expect(find.byType(SetupWizardScreen), findsNothing);
      expect(find.byType(BootScreen), findsNothing);
    },
  );
}
