import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/screens/server_recovery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('says it is the network, not the setup', (tester) async {
    await tester.pumpWidget(
      _wrap(const ServerRecoveryScreen(serverIp: 'http://192.168.1.10:8000')),
    );

    // The paired phone must not be told to pair again.
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Start over'), findsOneWidget);
    expect(find.textContaining('still set up'), findsOneWidget);
    expect(find.text('http://192.168.1.10:8000'), findsOneWidget);
  });

  testWidgets('start over clears the pairing and opens the wizard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_ip': 'http://192.168.1.10:8000',
      'secret_token': 's3cret',
      'pet_name': 'Berci',
      'is_setup_completed': true,
    });
    await tester.pumpWidget(
      _wrap(const ServerRecoveryScreen(serverIp: 'http://192.168.1.10:8000')),
    );

    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secret_token'), isNull);
    expect(prefs.getString('server_ip'), isNull);
    expect(prefs.getString('pet_name'), isNull);
    expect(prefs.getBool('is_setup_completed'), isFalse);
  });
}
