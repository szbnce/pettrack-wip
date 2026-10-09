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
}
