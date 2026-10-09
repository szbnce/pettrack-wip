import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/server_url.dart';

/// The API session: a short-lived access token plus a rotating refresh token.
///
/// Screens read [token] synchronously at request time and a background
/// refresh keeps it current, so no token is threaded through constructors.
/// Installations from before sessions existed simply keep their old token —
/// there is no refresh token to rotate and nothing here gets in the way.
class AuthService {
  static const accessKey = 'jwt_token';
  static const refreshKey = 'refresh_token';
  static const expiresAtKey = 'token_expires_at'; // ms since epoch
  static const roleKey = 'token_role'; // 'viewer' or 'monitor'
  // The monitor screen's historical storage key — kept mirrored so older
  // monitor builds still find their token after a refresh.
  static const monitorAccessKey = 'server_token';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// The current access token — read live so every request sees the latest.
  static String get token => _prefs?.getString(accessKey) ?? '';

  static Map<String, String> get headers => {'x-api-token': token};

  static bool get hasRefreshToken =>
      (_prefs?.getString(refreshKey) ?? '').isNotEmpty;

  static Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Store a session returned by login or refresh. [role] is 'viewer' or
  /// 'monitor' — a monitor session keeps the legacy key mirrored too.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
    required String role,
  }) async {
    final p = await _p;
    await p.setString(accessKey, accessToken);
    await p.setString(refreshKey, refreshToken);
    await p.setInt(
      expiresAtKey,
      DateTime.now().millisecondsSinceEpoch + expiresInSeconds * 1000,
    );
    await p.setString(roleKey, role);
    if (role == 'monitor') await p.setString(monitorAccessKey, accessToken);
  }

  /// Swap the refresh token for a new pair shortly before the access token
  /// expires. Returns false when there is nothing to do (no refresh token,
  /// not due yet) or the server refuses — callers just carry on with the
  /// current token.
  static Future<bool> refreshIfNeeded({
    String? serverIp,
    bool force = false,
  }) async {
    final p = await _p;
    final refresh = p.getString(refreshKey) ?? '';
    if (refresh.isEmpty) return false;
    final expiresAt = p.getInt(expiresAtKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now < expiresAt - 5 * 60 * 1000) return false;
    final raw = serverIp ?? p.getString('server_ip') ?? '';
    if (raw.isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse('${normalizeServerUrl(raw)}/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await saveSession(
        accessToken: data['token'] as String,
        refreshToken: data['refresh_token'] as String,
        expiresInSeconds: data['expires_in'] as int,
        role: p.getString(roleKey) ?? 'viewer',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sign out: revoke the session server-side (best effort — logout is
  /// idempotent there) and forget it locally either way.
  static Future<void> logout({String? serverIp}) async {
    final p = await _p;
    final refresh = p.getString(refreshKey) ?? '';
    final raw = serverIp ?? p.getString('server_ip') ?? '';
    if (refresh.isNotEmpty && raw.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('${normalizeServerUrl(raw)}/api/auth/logout'),
              headers: {'Content-Type': 'application/json', ...headers},
              body: jsonEncode({'refresh_token': refresh}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Offline: the tokens expire on their own; clear them here anyway.
      }
    }
    await p.remove(accessKey);
    await p.remove(refreshKey);
    await p.remove(expiresAtKey);
    await p.remove(roleKey);
    await p.remove(monitorAccessKey);
  }

  /// The access token from a login response body. Current servers answer
  /// with "token"; the oldest ones used "secret" for the same value —
  /// accept either so an old server keeps every screen working.
  static String? tokenFromLoginBody(dynamic body) {
    if (body is! Map) return null;
    final token = body['token'] ?? body['secret'];
    return token is String && token.isNotEmpty ? token : null;
  }

  /// Log in with the pairing secret — the recovery path for a phone that
  /// still knows its server and secret but has no live session (expired,
  /// revoked, or cleared). True when a fresh session was stored.
  static Future<bool> loginWithSecret({
    required String serverIp,
    required String secret,
  }) async {
    if (serverIp.isEmpty || secret.isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse('${normalizeServerUrl(serverIp)}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'secret': secret}),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      final token = tokenFromLoginBody(body);
      if (token == null) return false;
      final refresh = body['refresh_token'];
      final expires = body['expires_in'];
      await saveSession(
        accessToken: token,
        refreshToken: refresh is String ? refresh : '',
        expiresInSeconds: expires is num ? expires.toInt() : 3600,
        role: 'viewer',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
