import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/server_url.dart';

void main() {
  group('normalizeServerUrl', () {
    test('bare local IP gets scheme and default port', () {
      expect(normalizeServerUrl('192.168.1.100'), 'http://192.168.1.100:9500');
    });

    test('IP with port keeps the port', () {
      expect(
        normalizeServerUrl('192.168.1.100:9000'),
        'http://192.168.1.100:9000',
      );
    });

    test('full URL is untouched', () {
      expect(
        normalizeServerUrl('http://192.168.1.100:9500'),
        'http://192.168.1.100:9500',
      );
    });

    test('https host keeps its scheme and no forced port', () {
      expect(
        normalizeServerUrl('https://pet.example.com'),
        'https://pet.example.com',
      );
    });

    test('localhost gets the default port', () {
      expect(normalizeServerUrl('localhost'), 'http://localhost:9500');
    });

    test('LAN hostname is not forced onto port 9500', () {
      // Non-IP hosts may live behind any port; the user knows theirs.
      expect(normalizeServerUrl('myserver.local'), 'http://myserver.local');
    });

    test('whitespace is trimmed', () {
      expect(
        normalizeServerUrl('  192.168.1.100  '),
        'http://192.168.1.100:9500',
      );
    });

    test('empty string stays empty', () {
      expect(normalizeServerUrl(''), '');
    });
  });

  group('isValidNtfyUrl', () {
    test('a public ntfy topic is publishable', () {
      expect(isValidNtfyUrl('https://ntfy.sh/my-secret-topic'), isTrue);
    });

    test('a self-hosted ntfy on the LAN is publishable', () {
      expect(isValidNtfyUrl('http://192.168.1.50:8080/pets'), isTrue);
    });

    test('surrounding whitespace is forgiven', () {
      expect(isValidNtfyUrl('  https://ntfy.sh/pets  '), isTrue);
    });

    test('bare text is not a URL', () {
      expect(isValidNtfyUrl('not a url'), isFalse);
    });

    test('non-http schemes are rejected', () {
      expect(isValidNtfyUrl('ftp://example.com/pets'), isFalse);
      expect(isValidNtfyUrl('mailto:me@example.com'), isFalse);
    });

    test('a host is required', () {
      expect(isValidNtfyUrl('https://'), isFalse);
      expect(isValidNtfyUrl(''), isFalse);
    });
  });
}
