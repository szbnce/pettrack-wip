import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/screens/language_screen.dart';

Widget _wrap(Widget child, {Locale? locale}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: child,
  );
}

void main() {
  testWidgets('language picker shows every supported language', (tester) async {
    await tester.pumpWidget(_wrap(const LanguageScreen()));

    expect(find.text('Choose Language'), findsOneWidget);
    expect(find.text('Magyar'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('中文 (AI-GENERATED)'), findsOneWidget);
    expect(find.text('Italiano (AI-GENERATED)'), findsOneWidget);
    expect(find.text('Deutsch (AI-GENERATED)'), findsOneWidget);
    expect(find.text('日本語 (AI-GENERATED)'), findsOneWidget);
    expect(find.text('한국어 (AI-GENERATED)'), findsOneWidget);
  });

  testWidgets('language picker localizes its title', (tester) async {
    await tester.pumpWidget(
      _wrap(const LanguageScreen(), locale: const Locale('hu')),
    );

    expect(find.text('Válassz nyelvet'), findsOneWidget);
    expect(find.text('Choose Language'), findsNothing);
    expect(find.text('Magyar (AI-GENERÁLT)'), findsNothing);
  });
}
