import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/utils/pet_labels.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('zoneAlertLabel', () {
    test('names the pet in the notification copy', () {
      expect(
        zoneAlertLabel(l10n, 'Berci'),
        'Tell me when Berci enters or leaves a zone',
      );
    });

    test('an unnamed pet gets the generic line', () {
      expect(zoneAlertLabel(l10n, ''), l10n.alertsZoneGeneric);
    });

    test('whitespace is not a name', () {
      expect(zoneAlertLabel(l10n, '   '), l10n.alertsZoneGeneric);
    });

    test('the name is trimmed into the sentence', () {
      expect(
        zoneAlertLabel(l10n, '  Berci  '),
        'Tell me when Berci enters or leaves a zone',
      );
    });
  });
}
