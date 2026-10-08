import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/arming.dart';
import 'package:pettrack_app/utils/settings_backup.dart';

void main() {
  Map<String, Object?> fullPrefs() => {
    'server_ip': 'http://192.168.1.50:8000',
    'secret_token': 's3cret',
    'pet_name': 'Mogyi',
    'pet_type': 'rabbit',
    'profile_pic': 'aGVsbG8=',
    'language_code': 'hu',
    'theme_mode': 'dark',
    'alerts_zone_enabled': true,
    'alerts_sound_enabled': false,
    'alerts_battery_enabled': true,
    'alerts_battery_threshold': 20.0,
    'quiet_hours_enabled': true,
    'quiet_hours_from': 23 * 60,
    'quiet_hours_to': 7 * 60,
    // Session and device material must never travel in a backup.
    'jwt_token': 'eyJhbGciOi...',
    'refresh_token': 'r3fresh',
    'client_id': 'device-42',
    'app_mode': 'client',
    'is_setup_completed': true,
  };

  Map<String, Object?> fullServer() => {
    'replay_retention_days': 14,
    'ntfy_url': 'https://ntfy.sh/pettrack',
    'ntfy_token': 'ntfy-secret',
    'ntfy_lang': 'hu',
    'quiet_hours_enabled': true,
    'quiet_hours_from': 23 * 60,
    'quiet_hours_to': 7 * 60,
    'arming': {
      'mode': 'schedule',
      'schedule': [
        {
          'days': [1, 2, 3],
          'from_min': 540,
          'to_min': 1020,
        },
      ],
      'armed': true,
    },
  };

  group('buildSettingsBackup', () {
    test('carries the setup and its identity', () {
      final created = DateTime(2026, 10, 9, 12, 30);
      final doc = buildSettingsBackup(
        prefs: fullPrefs(),
        server: fullServer(),
        createdAt: created,
      );

      expect(doc['kind'], settingsBackupKind);
      expect(doc['version'], settingsBackupVersion);
      expect(doc['created_at'], created.toIso8601String());
      expect(doc['connection'], {
        'server_ip': 'http://192.168.1.50:8000',
        'secret_token': 's3cret',
      });
      expect(doc['pet'], {
        'name': 'Mogyi',
        'type': 'rabbit',
        'profile_pic': 'aGVsbG8=',
      });
      final preferences = doc['preferences'] as Map;
      expect(preferences['language_code'], 'hu');
      expect(preferences['theme_mode'], 'dark');
      expect(preferences['alerts_battery_threshold'], 20.0);
      expect(preferences['quiet_hours_from'], 23 * 60);
      final server = doc['server'] as Map;
      expect(server['replay_retention_days'], 14);
      expect(server['arming'], {
        'mode': 'schedule',
        'schedule': [
          {
            'days': [1, 2, 3],
            'from_min': 540,
            'to_min': 1020,
          },
        ],
      });
    });

    test('leaves session material at home', () {
      final doc = buildSettingsBackup(prefs: fullPrefs());
      final text = jsonEncode(doc);

      expect(text, isNot(contains('eyJhbGciOi')));
      expect(text, isNot(contains('r3fresh')));
      expect(text, isNot(contains('jwt_token')));
      expect(text, isNot(contains('refresh_token')));
      expect(text, isNot(contains('device-42')));
      expect(text, isNot(contains('client_id')));
    });

    test('a phone with nothing set still exports', () {
      final doc = buildSettingsBackup(prefs: {});

      expect(doc['kind'], settingsBackupKind);
      expect(doc['connection'], isEmpty);
      expect(doc['pet'], isEmpty);
      expect(doc['preferences'], isEmpty);
      expect(doc.containsKey('server'), isFalse);
    });

    test('junk pref values are dropped, not guessed', () {
      final doc = buildSettingsBackup(
        prefs: {
          'alerts_battery_threshold': 'high',
          'quiet_hours_from': 9999,
          'alerts_zone_enabled': 'yes',
          'language_code': '',
        },
      );

      expect(doc['preferences'], isEmpty);
    });
  });

  group('parseSettingsBackup', () {
    test('round-trips a full document', () {
      final doc = buildSettingsBackup(
        prefs: fullPrefs(),
        server: fullServer(),
        createdAt: DateTime(2026, 10, 9),
      );

      final parsed = parseSettingsBackup(jsonEncode(doc));

      expect(parsed, isNotNull);
      expect(parsed!['kind'], settingsBackupKind);
      expect(parsed['connection'], doc['connection']);
      expect(parsed['preferences'], doc['preferences']);
    });

    test('refuses anything that is not a backup', () {
      expect(parseSettingsBackup('not json'), isNull);
      expect(parseSettingsBackup('[1, 2, 3]'), isNull);
      expect(parseSettingsBackup('"hello"'), isNull);
      expect(
        parseSettingsBackup(jsonEncode({'kind': 'other', 'version': 1})),
        isNull,
      );
    });

    test('refuses versions it cannot honour', () {
      expect(
        parseSettingsBackup(
          jsonEncode({'kind': settingsBackupKind, 'version': 0}),
        ),
        isNull,
      );
      expect(
        parseSettingsBackup(
          jsonEncode({'kind': settingsBackupKind, 'version': 2}),
        ),
        isNull,
      );
      expect(
        parseSettingsBackup(
          jsonEncode({'kind': settingsBackupKind, 'version': '1'}),
        ),
        isNull,
      );
      expect(
        parseSettingsBackup(jsonEncode({'kind': settingsBackupKind})),
        isNull,
      );
    });
  });

  group('restorePrefsFrom', () {
    test('writes every carried preference with its setter type', () {
      final doc = buildSettingsBackup(prefs: fullPrefs());
      final writes = restorePrefsFrom(doc);

      expect(writes['server_ip'], 'http://192.168.1.50:8000');
      expect(writes['secret_token'], 's3cret');
      expect(writes['pet_name'], 'Mogyi');
      expect(writes['pet_type'], 'rabbit');
      expect(writes['profile_pic'], 'aGVsbG8=');
      expect(writes['language_code'], 'hu');
      expect(writes['theme_mode'], 'dark');
      expect(writes['alerts_zone_enabled'], true);
      expect(writes['alerts_sound_enabled'], false);
      expect(writes['alerts_battery_threshold'], isA<double>());
      expect(writes['alerts_battery_threshold'], 20.0);
      expect(writes['quiet_hours_from'], 23 * 60);
      expect(writes['quiet_hours_to'], 7 * 60);
      // Nothing session-shaped ever comes back.
      expect(writes.containsKey('jwt_token'), isFalse);
      expect(writes.containsKey('client_id'), isFalse);
      expect(writes.containsKey('is_setup_completed'), isFalse);
    });

    test('a partial backup writes only what it has', () {
      final writes = restorePrefsFrom({
        'kind': settingsBackupKind,
        'version': 1,
        'connection': {'server_ip': 'http://x:8000'},
        'preferences': {'theme_mode': 'light'},
      });

      expect(writes, {'server_ip': 'http://x:8000', 'theme_mode': 'light'});
    });

    test('empty connection fields never wipe a working login', () {
      final writes = restorePrefsFrom({
        'kind': settingsBackupKind,
        'version': 1,
        'connection': {'server_ip': '', 'secret_token': ''},
        'pet': {'name': '', 'profile_pic': null},
      });

      expect(writes, isEmpty);
    });
  });

  group('patches', () {
    test('server settings patch keeps empty strings as "off"', () {
      final doc = buildSettingsBackup(
        prefs: {},
        server: {'ntfy_url': '', 'ntfy_token': '', 'replay_retention_days': 7},
      );

      final patch = serverSettingsPatch(doc);

      expect(patch['ntfy_url'], '');
      expect(patch['ntfy_token'], '');
      expect(patch['replay_retention_days'], 7);
    });

    test('arming patch mirrors the schedule, junk and all', () {
      final doc = buildSettingsBackup(
        prefs: {},
        server: {
          'arming': {
            'mode': 'schedule',
            'schedule': [
              {
                'days': [5, 5, 1],
                'from_min': 60,
                'to_min': 120,
              },
              {'days': []},
            ],
          },
        },
      );

      expect(armingPatch(doc), {
        'mode': 'schedule',
        'schedule': [
          {
            'days': [1, 5],
            'from_min': 60,
            'to_min': 120,
          },
        ],
      });
    });

    test('arming patch stays empty without an arming snapshot', () {
      expect(armingPatch(buildSettingsBackup(prefs: fullPrefs())), isEmpty);
      expect(
        armingPatch({
          'kind': settingsBackupKind,
          'version': 1,
          'server': {
            'arming': {'mode': 'banana', 'schedule': 'nope'},
          },
        }),
        isEmpty,
      );
    });

    test('pet patch clears a photo the backup never had', () {
      final doc = {
        'kind': settingsBackupKind,
        'version': 1,
        'pet': {'name': 'Mogyi', 'type': 'rabbit'},
      };

      expect(petPatch(doc), {
        'name': 'Mogyi',
        'type': 'rabbit',
        'profile_pic': null,
      });
      expect(petPatch(buildSettingsBackup(prefs: {})), isEmpty);
    });
  });

  group('schedule wiring', () {
    test('windows survive a round trip in the server shape', () {
      final window = ArmingWindow.workweek();
      final doc = buildSettingsBackup(
        prefs: {},
        server: {
          'arming': {
            'mode': armingModeOn,
            'schedule': [window.toJson()],
          },
        },
      );

      final patched = armingPatch(doc);
      final schedule = parseArmingSchedule(patched['schedule']);

      expect(schedule, hasLength(1));
      expect(schedule.single.days, window.days);
      expect(schedule.single.fromMin, window.fromMin);
      expect(schedule.single.toMin, window.toMin);
    });
  });
}
