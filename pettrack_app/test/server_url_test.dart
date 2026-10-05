import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/server_url.dart';

void main() {
  group('normalizeServerUrl', () {
    test('bare local IP gets scheme and default port', () {
      expect(normalizeServerUrl('192.168.1.100'), 'http://192.168.1.100:8000');
    });

    test('IP with port keeps the port', () {
      expect(normalizeServerUrl('192.168.1.100:9000'), 'http://192.168.1.100:9000');
    });

    test('full URL is untouched', () {
      expect(
        normalizeServerUrl('http://192.168.1.100:8000'),
        'http://192.168.1.100:8000',
      );
    });

    test('https host keeps its scheme and no forced port', () {
      expect(
        normalizeServerUrl('https://pet.example.com'),
        'https://pet.example.com',
      );
    });

    test('localhost gets the default port', () {
      expect(normalizeServerUrl('localhost'), 'http://localhost:8000');
    });

    test('LAN hostname is not forced onto port 8000', () {
      // Non-IP hosts may live behind any port; the user knows theirs.
      expect(normalizeServerUrl('myserver.local'), 'http://myserver.local');
    });

    test('whitespace is trimmed', () {
      expect(
        normalizeServerUrl('  192.168.1.100  '),
        'http://192.168.1.100:8000',
      );
    });

    test('empty string stays empty', () {
      expect(normalizeServerUrl(''), '');
    });
  });
}
