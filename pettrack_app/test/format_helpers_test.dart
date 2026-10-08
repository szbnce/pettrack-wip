import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/utils/format_helpers.dart';

void main() {
  group('formatBytes', () {
    test('small sizes stay bytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1023), '1023 B');
    });

    test('steps up through KB, MB, GB, TB', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(512 * 1024 * 1024), '512 MB');
      expect(formatBytes((1.5 * 1024 * 1024 * 1024).round()), '1.5 GB');
      expect(formatBytes(4 * 1024 * 1024 * 1024 * 1024), '4.0 TB');
    });

    test('drops the decimal at 100 and above', () {
      expect(formatBytes(150 * 1024 * 1024), '150 MB');
    });
  });

  group('formatDurationSeconds', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('under a minute stays in seconds', () {
      expect(formatDurationSeconds(l10n, 20), '20 s');
      expect(formatDurationSeconds(l10n, 59.4), '59 s');
    });

    test('minutes', () {
      expect(formatDurationSeconds(l10n, 90), '1 min');
      expect(formatDurationSeconds(l10n, 45 * 60), '45 min');
    });

    test('hours, with and without a minute remainder', () {
      expect(formatDurationSeconds(l10n, 3725), '1 h 2 min');
      expect(formatDurationSeconds(l10n, 7200), '2 h');
    });
  });
}
