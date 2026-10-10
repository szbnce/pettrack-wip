import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/pairing.dart';

void main() {
  group('parsePairingPayload', () {
    test('takes a well-formed payload as it is', () {
      expect(parsePairingPayload('{"ip": "192.168.1.5:8000", "secret": "s"}'), {
        'ip': '192.168.1.5:8000',
        'secret': 's',
      });
    });

    test('refuses anything that is not a pairing payload', () {
      expect(parsePairingPayload('not json'), isNull);
      expect(parsePairingPayload('["ip", "secret"]'), isNull);
      expect(parsePairingPayload('"ip and secret in a sentence"'), isNull);
      expect(parsePairingPayload('{"ip": "x"}'), isNull);
      expect(parsePairingPayload('{"secret": "x"}'), isNull);
    });

    test('refuses wrong-typed or empty fields', () {
      expect(parsePairingPayload('{"ip": 5, "secret": "s"}'), isNull);
      expect(parsePairingPayload('{"ip": "x", "secret": true}'), isNull);
      expect(parsePairingPayload('{"ip": "", "secret": "s"}'), isNull);
      expect(parsePairingPayload('{"ip": "x", "secret": ""}'), isNull);
      expect(parsePairingPayload('{"ip": null, "secret": null}'), isNull);
    });
  });

  group('pairingFields', () {
    test('validates decoded values the same way', () {
      expect(pairingFields({'ip': 'a', 'secret': 'b'}), {
        'ip': 'a',
        'secret': 'b',
      });
      expect(pairingFields(['a']), isNull);
      expect(pairingFields('junk'), isNull);
      expect(pairingFields(null), isNull);
    });
  });

  group('pairingQrPayload', () {
    test('drops the scheme so the monitor can dial it', () {
      final fields = parsePairingPayload(
        pairingQrPayload('http://192.168.1.5:8000', 's'),
      );
      expect(fields, {'ip': '192.168.1.5:8000', 'secret': 's'});
    });

    test('tidies a trailing slash and an https scheme', () {
      final fields = parsePairingPayload(
        pairingQrPayload('https://pet.home/', 's'),
      );
      expect(fields, {'ip': 'pet.home', 'secret': 's'});
    });

    test('a payload it builds is a payload it accepts', () {
      // The round trip is the point: whatever the dashboard shows as a QR
      // must be scannable by the same parser the monitor uses.
      for (final url in [
        'http://10.0.0.2:8000',
        'https://pet.example.com',
        'http://192.168.1.10:8000/',
      ]) {
        expect(parsePairingPayload(pairingQrPayload(url, 'abc')), isNotNull);
      }
    });
  });
}
