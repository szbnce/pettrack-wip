import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.init();
    });

    test('saveSession stores the pair and exposes the access token', () async {
      await AuthService.saveSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresInSeconds: 3600,
        role: 'viewer',
      );
      expect(AuthService.token, 'access-1');
      expect(AuthService.headers, {'x-api-token': 'access-1'});
      expect(AuthService.hasRefreshToken, isTrue);
    });

    test('a monitor session keeps the legacy key mirrored', () async {
      await AuthService.saveSession(
        accessToken: 'access-2',
        refreshToken: 'refresh-2',
        expiresInSeconds: 3600,
        role: 'monitor',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('server_token'), 'access-2');
    });

    test('refresh is a no-op without a refresh token', () async {
      expect(await AuthService.refreshIfNeeded(serverIp: 'http://x'), isFalse);
    });

    test('refresh waits while the access token is still fresh', () async {
      await AuthService.saveSession(
        accessToken: 'access-3',
        refreshToken: 'refresh-3',
        expiresInSeconds: 3600,
        role: 'viewer',
      );
      // Just minted — not due yet, so no request is attempted.
      expect(
        await AuthService.refreshIfNeeded(serverIp: 'http://127.0.0.1:1'),
        isFalse,
      );
    });

    test('logout forgets the whole session', () async {
      await AuthService.saveSession(
        accessToken: 'access-4',
        refreshToken: 'refresh-4',
        expiresInSeconds: 3600,
        role: 'monitor',
      );
      await AuthService.logout();
      expect(AuthService.token, '');
      expect(AuthService.hasRefreshToken, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('server_token'), isNull);
      expect(prefs.getString('token_role'), isNull);
    });
  });

  group('tokenFromLoginBody', () {
    test('current servers answer with "token"', () {
      expect(AuthService.tokenFromLoginBody({'token': 'abc'}), 'abc');
    });

    test('the oldest servers called the same value "secret"', () {
      expect(AuthService.tokenFromLoginBody({'secret': 'legacy'}), 'legacy');
      // Both present (the current shape): "token" wins.
      expect(
        AuthService.tokenFromLoginBody({'token': 'new', 'secret': 'old'}),
        'new',
      );
    });

    test('junk in, no token out', () {
      expect(AuthService.tokenFromLoginBody(null), isNull);
      expect(AuthService.tokenFromLoginBody('not a map'), isNull);
      expect(AuthService.tokenFromLoginBody({}), isNull);
      expect(AuthService.tokenFromLoginBody({'token': ''}), isNull);
    });
  });
}
