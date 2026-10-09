import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/feed_export.dart';

void main() {
  group('csvField', () {
    test('plain cells stay bare', () {
      expect(csvField('zone_enter'), 'zone_enter');
      expect(csvField(''), '');
    });

    test('delimiters, quotes and newlines are quoted', () {
      expect(csvField('a,b'), '"a,b"');
      expect(csvField('say "hi"'), '"say ""hi"""');
      expect(csvField('line1\nline2'), '"line1\nline2"');
    });
  });

  group('buildFeedCsv', () {
    test('header, rows and CRLF endings', () {
      final csv = buildFeedCsv([
        [
          '1728000000',
          '2026-10-09T14:00:00.000',
          'zone_enter',
          'Kitchen',
          'In',
          'ok',
        ],
      ]);
      expect(
        csv,
        startsWith('timestamp,iso_time,event_type,zone,title,details\r\n'),
      );
      expect(
        csv,
        contains('1728000000,2026-10-09T14:00:00.000,zone_enter,Kitchen,In,ok'),
      );
      expect(csv.endsWith('\r\n'), isTrue);
    });

    test('a nasty zone name survives the round trip', () {
      final csv = buildFeedCsv([
        ['1', 't', 'zone_left', 'Kitchen, "west"', 'Left', 'x'],
      ]);
      expect(csv, contains('"Kitchen, ""west"""'));
    });

    test('no rows still gives the header', () {
      expect(
        buildFeedCsv([]),
        'timestamp,iso_time,event_type,zone,title,details\r\n',
      );
    });
  });

  group('feedCsvFileName', () {
    test('is sortable and stamped with the minute', () {
      expect(
        feedCsvFileName(DateTime(2026, 10, 9, 14, 5)),
        'pettrack-feed-20261009-1405.csv',
      );
    });
  });
}
