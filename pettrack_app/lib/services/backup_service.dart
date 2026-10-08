import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/server_url.dart';
import '../utils/settings_backup.dart';
import 'auth_service.dart';

/// What a restore achieved.
enum BackupRestoreOutcome {
  /// Not a PetTrack backup — nothing was touched.
  invalid,

  /// Restored here and on the server.
  restored,

  /// Restored on this phone; the server did not take its part (unreachable,
  /// or the secret in the file no longer opens the door).
  restoredOffline,
}

/// Backup and restore over the document format in [settings_backup].
///
/// Export snapshots the server (retention, remote alerts, quiet hours,
/// arming) best-effort and packs it with the local setup; restore writes the
/// local part unconditionally and pushes the server part when the secret in
/// the file can still log in — a phone without a network still gets its
/// setup back.
class BackupService {
  /// The backup document for what this phone holds, plus whatever the
  /// server will say right now.
  static Future<Map<String, dynamic>> buildDocument() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = <String, Object?>{
      for (final key in prefs.getKeys()) key: prefs.get(key),
    };
    return buildSettingsBackup(
      prefs: raw,
      server: await _fetchServerSnapshot(),
    );
  }

  /// Applies a backup file. Local settings always land; pet, server settings
  /// and arming follow when the server answers.
  static Future<BackupRestoreOutcome> restore(String text) async {
    final doc = parseSettingsBackup(text);
    if (doc == null) return BackupRestoreOutcome.invalid;

    final prefs = await SharedPreferences.getInstance();
    final writes = restorePrefsFrom(doc);
    for (final entry in writes.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      }
    }

    final connection = doc['connection'];
    final ip = connection is Map ? connection['server_ip'] : null;
    final secret = connection is Map ? connection['secret_token'] : null;
    if (ip is! String || ip.isEmpty || secret is! String || secret.isEmpty) {
      return BackupRestoreOutcome.restoredOffline;
    }
    return _loginAndPush(ip, secret, doc);
  }

  /// The server's side of the setup — one document section built from the
  /// settings and arming endpoints. A fetch that fails just thins the
  /// snapshot; export must not die with the server.
  static Future<Map<String, Object?>?> _fetchServerSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('server_ip') ?? '';
    final token = AuthService.token;
    if (raw.isEmpty || token.isEmpty || raw.contains('demo_ip')) return null;
    final base = normalizeServerUrl(raw);
    final snapshot = <String, Object?>{};

    Future<void> fetch(String path, {String? into}) async {
      try {
        final response = await http
            .get(Uri.parse('$base$path'), headers: {'x-api-token': token})
            .timeout(const Duration(seconds: 4));
        if (response.statusCode != 200) return;
        final body = jsonDecode(response.body);
        if (body is! Map) return;
        if (into != null) {
          snapshot[into] = Map<String, Object?>.from(body);
        } else {
          snapshot.addAll(Map<String, Object?>.from(body));
        }
      } catch (_) {
        // Thin snapshot, not a failed export.
      }
    }

    await fetch('/api/settings');
    await fetch('/api/arming', into: 'arming');
    return snapshot.isEmpty ? null : snapshot;
  }

  static Future<BackupRestoreOutcome> _loginAndPush(
    String ip,
    String secret,
    Map<String, dynamic> doc,
  ) async {
    try {
      final base = normalizeServerUrl(ip);
      final login = await http
          .post(
            Uri.parse('$base/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'secret': secret}),
          )
          .timeout(const Duration(seconds: 4));
      if (login.statusCode != 200) return BackupRestoreOutcome.restoredOffline;
      final body = jsonDecode(login.body);
      final token = body is Map ? body['token'] : null;
      if (token is! String || token.isEmpty) {
        return BackupRestoreOutcome.restoredOffline;
      }
      final refresh = body['refresh_token'];
      final expires = body['expires_in'];
      await AuthService.saveSession(
        accessToken: token,
        refreshToken: refresh is String ? refresh : '',
        expiresInSeconds: expires is num ? expires.toInt() : 3600,
        role: 'viewer',
      );
      final synced = await _pushServerState(doc, base);
      return synced
          ? BackupRestoreOutcome.restored
          : BackupRestoreOutcome.restoredOffline;
    } catch (_) {
      return BackupRestoreOutcome.restoredOffline;
    }
  }

  /// Pet, server settings and arming, in that order. Every push is
  /// best-effort and the outcome reports honestly if any refused.
  static Future<bool> _pushServerState(
    Map<String, dynamic> doc,
    String base,
  ) async {
    var ok = true;

    Future<void> post(String path, Map<String, Object?> body) async {
      if (body.isEmpty) return;
      try {
        final response = await http
            .post(
              Uri.parse('$base$path'),
              headers: {
                'x-api-token': AuthService.token,
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 4));
        if (response.statusCode != 200) ok = false;
      } catch (_) {
        ok = false;
      }
    }

    await post('/api/pet', petPatch(doc));
    await post('/api/settings', serverSettingsPatch(doc));
    await post('/api/arming', armingPatch(doc));
    return ok;
  }
}
