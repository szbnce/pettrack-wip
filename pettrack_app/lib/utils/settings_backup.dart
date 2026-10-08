import 'dart:convert';

import 'arming.dart';

/// Settings backup: one JSON document that restores a whole PetTrack setup.
///
/// A backup carries the pairing secret so a new phone can log in without
/// scanning a QR code again — which also makes the file sensitive: treat it
/// like a password. Session material (JWTs, device ids) is deliberately left
/// out; restore mints a fresh session from the secret instead of copying
/// one.
const String settingsBackupKind = 'pettrack_settings_backup';
const int settingsBackupVersion = 1;

/// Builds the backup document from a raw SharedPreferences snapshot plus the
/// optional server-side snapshot (settings + arming). Unknown keys are
/// ignored, missing ones simply leave the document thinner.
Map<String, dynamic> buildSettingsBackup({
  required Map<String, Object?> prefs,
  Map<String, Object?>? server,
  DateTime? createdAt,
}) {
  return {
    'kind': settingsBackupKind,
    'version': settingsBackupVersion,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    'connection': {
      'server_ip': ?_asString(prefs['server_ip']),
      'secret_token': ?_asString(prefs['secret_token']),
    },
    'pet': {
      'name': ?_asNonEmpty(prefs['pet_name']),
      'type': ?_asNonEmpty(prefs['pet_type']),
      'profile_pic': ?_asNonEmpty(prefs['profile_pic']),
    },
    'preferences': {
      'language_code': ?_asNonEmpty(prefs['language_code']),
      'theme_mode': ?_asNonEmpty(prefs['theme_mode']),
      'alerts_zone_enabled': ?_asBool(prefs['alerts_zone_enabled']),
      'alerts_sound_enabled': ?_asBool(prefs['alerts_sound_enabled']),
      'alerts_battery_enabled': ?_asBool(prefs['alerts_battery_enabled']),
      'alerts_battery_threshold': ?_asDouble(
        prefs['alerts_battery_threshold'],
        0,
        100,
      ),
      'quiet_hours_enabled': ?_asBool(prefs['quiet_hours_enabled']),
      'quiet_hours_from': ?_asInt(prefs['quiet_hours_from'], 0, 1439),
      'quiet_hours_to': ?_asInt(prefs['quiet_hours_to'], 0, 1439),
    },
    'server': ?_serverSection(server),
  };
}

/// Parses a backup document. Returns null for anything that is not one —
/// broken JSON, a foreign file, or a version from the future that this build
/// must not guess at.
Map<String, dynamic>? parseSettingsBackup(String text) {
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;
  final doc = Map<String, dynamic>.from(decoded);
  if (doc['kind'] != settingsBackupKind) return null;
  final version = doc['version'];
  if (version is! int || version < 1 || version > settingsBackupVersion) {
    return null;
  }
  return doc;
}

/// The SharedPreferences writes a restore applies — already typed for the
/// setters. Junk is dropped rather than crashing; absent sections write
/// nothing.
Map<String, Object> restorePrefsFrom(Map<String, dynamic> backup) {
  final out = <String, Object>{};
  final connection = _section(backup, 'connection');
  final ip = _asNonEmpty(connection['server_ip']);
  final secret = _asNonEmpty(connection['secret_token']);
  if (ip != null) out['server_ip'] = ip;
  if (secret != null) out['secret_token'] = secret;

  final pet = _section(backup, 'pet');
  final name = _asNonEmpty(pet['name']);
  final type = _asNonEmpty(pet['type']);
  final pic = _asNonEmpty(pet['profile_pic']);
  if (name != null) out['pet_name'] = name;
  if (type != null) out['pet_type'] = type;
  if (pic != null) out['profile_pic'] = pic;

  final prefs = _section(backup, 'preferences');
  final language = _asNonEmpty(prefs['language_code']);
  final theme = _asNonEmpty(prefs['theme_mode']);
  if (language != null) out['language_code'] = language;
  if (theme != null) out['theme_mode'] = theme;
  for (final key in [
    'alerts_zone_enabled',
    'alerts_sound_enabled',
    'alerts_battery_enabled',
    'quiet_hours_enabled',
  ]) {
    final value = _asBool(prefs[key]);
    if (value != null) out[key] = value;
  }
  final threshold = _asDouble(prefs['alerts_battery_threshold'], 0, 100);
  if (threshold != null) out['alerts_battery_threshold'] = threshold;
  final quietFrom = _asInt(prefs['quiet_hours_from'], 0, 1439);
  final quietTo = _asInt(prefs['quiet_hours_to'], 0, 1439);
  if (quietFrom != null) out['quiet_hours_from'] = quietFrom;
  if (quietTo != null) out['quiet_hours_to'] = quietTo;
  return out;
}

/// The POST /api/pet body for a restore — empty when the backup carries no
/// pet section. A present section always sends all three fields so a photo
/// the backup never had is cleared rather than left behind.
Map<String, Object?> petPatch(Map<String, dynamic> backup) {
  final pet = _section(backup, 'pet');
  if (pet.isEmpty) return {};
  return {
    'name': _asNonEmpty(pet['name']) ?? '',
    'type': _asNonEmpty(pet['type']) ?? 'rabbit',
    'profile_pic': _asNonEmpty(pet['profile_pic']),
  };
}

/// The POST /api/settings body — only the fields the backup actually has.
Map<String, Object> serverSettingsPatch(Map<String, dynamic> backup) {
  final server = _section(backup, 'server');
  final out = <String, Object>{};
  final retention = _asInt(server['replay_retention_days'], 1, 365);
  if (retention != null) out['replay_retention_days'] = retention;
  // Empty strings are meaningful here — they switch the ntfy bridge off.
  for (final key in ['ntfy_url', 'ntfy_token', 'ntfy_lang']) {
    final value = server[key];
    if (value is String) out[key] = value;
  }
  final quietEnabled = _asBool(server['quiet_hours_enabled']);
  if (quietEnabled != null) out['quiet_hours_enabled'] = quietEnabled;
  final quietFrom = _asInt(server['quiet_hours_from'], 0, 1439);
  final quietTo = _asInt(server['quiet_hours_to'], 0, 1439);
  if (quietFrom != null) out['quiet_hours_from'] = quietFrom;
  if (quietTo != null) out['quiet_hours_to'] = quietTo;
  return out;
}

/// The POST /api/arming body — empty when the backup has no arming snapshot.
Map<String, Object> armingPatch(Map<String, dynamic> backup) {
  final armingRaw = _section(backup, 'server')['arming'];
  if (armingRaw is! Map) return {};
  final out = <String, Object>{};
  final mode = _asNonEmpty(armingRaw['mode']);
  if (mode != null &&
      (mode == armingModeOn ||
          mode == armingModeSchedule ||
          mode == armingModeOff)) {
    out['mode'] = mode;
  }
  if (armingRaw['schedule'] is List) {
    out['schedule'] = [
      for (final window in parseArmingSchedule(armingRaw['schedule']))
        window.toJson(),
    ];
  }
  return out;
}

Map<String, dynamic> _section(Map<String, dynamic> backup, String name) {
  final raw = backup[name];
  return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}

/// The server half of the document: retention, remote alerts, quiet hours
/// and arming. The snapshot may come straight off the wire, so every field
/// degrades on its own.
Map<String, dynamic>? _serverSection(Map<String, Object?>? server) {
  if (server == null) return null;
  final armingRaw = server['arming'];
  return {
    'replay_retention_days': ?_asInt(server['replay_retention_days'], 1, 365),
    // Empty strings are kept: they mean the bridge is off, not "unknown".
    'ntfy_url': ?_asString(server['ntfy_url']),
    'ntfy_token': ?_asString(server['ntfy_token']),
    'ntfy_lang': ?_asString(server['ntfy_lang']),
    'quiet_hours_enabled': ?_asBool(server['quiet_hours_enabled']),
    'quiet_hours_from': ?_asInt(server['quiet_hours_from'], 0, 1439),
    'quiet_hours_to': ?_asInt(server['quiet_hours_to'], 0, 1439),
    if (armingRaw is Map)
      'arming': {
        'mode': ?_asNonEmpty(armingRaw['mode']),
        'schedule': ?_asSchedule(armingRaw['schedule']),
      },
  };
}

List<Map<String, dynamic>>? _asSchedule(Object? raw) {
  if (raw is! List) return null;
  return [for (final window in parseArmingSchedule(raw)) window.toJson()];
}

String? _asString(Object? value) => value is String ? value : null;

String? _asNonEmpty(Object? value) {
  final text = _asString(value);
  return text == null || text.isEmpty ? null : text;
}

bool? _asBool(Object? value) => value is bool ? value : null;

int? _asInt(Object? value, int min, int max) {
  if (value is! num || value is bool) return null;
  final n = value.toInt();
  return n < min || n > max ? null : n;
}

double? _asDouble(Object? value, double min, double max) {
  if (value is! num || value is bool) return null;
  final n = value.toDouble();
  return n < min || n > max ? null : n;
}
