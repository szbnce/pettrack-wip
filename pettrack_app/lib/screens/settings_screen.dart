import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import '../app_info.dart';
import '../theme/colors.dart';
import '../utils/format_helpers.dart';
import '../utils/server_url.dart';
import '../main.dart';
import 'main_navigation.dart';
import '../services/notification_service.dart';
import '../services/wear_sync_service.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isSetup;
  const SettingsScreen({super.key, this.isSetup = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();
  final _tokenController = TextEditingController();
  final _petNameController = TextEditingController();
  String? _profilePicBase64;
  String _languageCode = 'hu';
  String _petType = 'rabbit';
  String _themeModeString = 'system';
  bool _alertsZoneEnabled = true;
  bool _alertsBatteryEnabled = true;
  bool _alertsSoundEnabled = true;
  double _batteryThreshold = 20.0;
  bool _quietHoursEnabled = false;
  int _quietHoursFrom = 23 * 60;
  int _quietHoursTo = 7 * 60;
  String? _serverVersion;
  bool _checkingVersion = false;
  bool _isLoading = true;

  // System health card (server watchdog: camera, disk, replay retention).
  Map<String, dynamic>? _health;
  bool _healthFailed = false;
  int _retentionDays = 14;

  // Remote alerts (ntfy bridge): topic URL + optional access token.
  final _ntfyUrlController = TextEditingController();
  final _ntfyTokenController = TextEditingController();
  bool _testingNtfy = false;

  String _getLocalizedPetType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'dog':
        return l10n.petTypeDog;
      case 'cat':
        return l10n.petTypeCat;
      case 'rabbit':
        return l10n.petTypeRabbit;
      case 'bird':
        return l10n.petTypeBird;
      case 'guineapig':
        return l10n.petTypeGuineaPig;
      default:
        return l10n.petTypeOther;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _tokenController.dispose();
    _petNameController.dispose();
    _ntfyUrlController.dispose();
    _ntfyTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('server_ip') ?? '';
    final token = prefs.getString('jwt_token') ?? '';

    setState(() {
      _ipController.text = ip;
      _tokenController.text = prefs.getString('secret_token') ?? '';
      _languageCode = prefs.getString('language_code') ?? 'hu';
      _themeModeString = prefs.getString('theme_mode') ?? 'system';
      _alertsZoneEnabled = prefs.getBool('alerts_zone_enabled') ?? true;
      _alertsBatteryEnabled = prefs.getBool('alerts_battery_enabled') ?? true;
      _alertsSoundEnabled = prefs.getBool('alerts_sound_enabled') ?? true;
      _batteryThreshold = prefs.getDouble('alerts_battery_threshold') ?? 20.0;
      _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
      _quietHoursFrom = prefs.getInt('quiet_hours_from') ?? 23 * 60;
      _quietHoursTo = prefs.getInt('quiet_hours_to') ?? 7 * 60;
    });

    if (ip.isNotEmpty && token.isNotEmpty && !ip.contains('demo_ip')) {
      try {
        final response = await http
            .get(Uri.parse('$ip/api/pet'), headers: AuthService.headers)
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200 && mounted) {
          final petData = jsonDecode(response.body);
          setState(() {
            _petNameController.text = petData['name'] ?? '';
            _petType = (petData['type'] ?? 'rabbit')
                .toString()
                .replaceFirst('petType', '')
                .toLowerCase();
            _profilePicBase64 = petData['profile_pic'];
          });

          if (_profilePicBase64 != null) {
            await prefs.setString('profile_pic', _profilePicBase64!);
          } else {
            await prefs.remove('profile_pic');
          }
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToLoadPetProfile(e.toString()))),
          );
        }
      }
    }

    if (ip.isNotEmpty) {
      _checkServerVersion();
      _fetchSystemHealth();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Normalizes user input to the scheme-less "host:port" form the
  /// monitor app expects in the pairing QR code.
  String _normalizeHost(String input) {
    var ip = input.trim();
    if (ip.startsWith('http://')) ip = ip.replaceAll('http://', '');
    if (ip.startsWith('https://')) ip = ip.replaceAll('https://', '');
    if (!ip.contains(':')) ip = '$ip:8000';
    return ip;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profilePicBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final ntfyUrl = _ntfyUrlController.text.trim();
    if (ntfyUrl.isNotEmpty && !isValidNtfyUrl(ntfyUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.alertsRemoteUrlInvalid)),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    String ip = _ipController.text.trim();
    if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
      ip = 'http://$ip';
    }

    final uri = Uri.tryParse(ip);
    if (uri != null && !uri.hasPort) {
      final host = uri.host;
      final isIpOrLocal =
          RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$').hasMatch(host) ||
          host == 'localhost';
      if (isIpOrLocal && uri.scheme != 'https') {
        ip = '${uri.scheme}://$host:8000${uri.path}';
      }
    }
    _ipController.text = ip;

    final secret = _tokenController.text.trim();

    setState(() => _isLoading = true);

    String jwtToken = prefs.getString('jwt_token') ?? '';
    final storedSecret = prefs.getString('secret_token') ?? '';

    // Get a fresh JWT when the secret changed or there is no valid token yet,
    // otherwise the save below would silently fail with the stale token.
    if (!ip.contains('demo_ip') && (secret != storedSecret || jwtToken.isEmpty)) {
      try {
        final loginRes = await http
            .post(
              Uri.parse('$ip/api/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'secret': secret}),
            )
            .timeout(const Duration(seconds: 3));
        if (loginRes.statusCode != 200) {
          throw Exception("Login Failed");
        }
        final loginBody = jsonDecode(loginRes.body) as Map<String, dynamic>;
        jwtToken = loginBody['token'];
        await AuthService.saveSession(
          accessToken: loginBody['token'] as String,
          refreshToken: loginBody['refresh_token'] as String? ?? '',
          expiresInSeconds: (loginBody['expires_in'] as num?)?.toInt() ?? 3600,
          role: 'viewer',
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidSecretToken)),
        );
        return;
      }
    }

    var petSaveFailed = false;
    try {
      await http
          .post(
            Uri.parse('$ip/api/pet'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-token': jwtToken,
            },
            body: jsonEncode({
              "name": _petNameController.text.trim(),
              "type": _petType,
              "profile_pic": _profilePicBase64,
            }),
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      // The local save below still happens — just don't claim success.
      petSaveFailed = true;
      debugPrint('pet profile save failed: $e');
    }

    // Remote alerts (ntfy) and the quiet-hours window the bridge honours.
    // Best effort: a briefly unreachable server must not lose the local save.
    try {
      await http
          .post(
            Uri.parse('$ip/api/settings'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-token': jwtToken,
            },
            body: jsonEncode({
              'ntfy_url': ntfyUrl,
              'ntfy_token': _ntfyTokenController.text.trim(),
              'ntfy_lang': _languageCode,
              'quiet_hours_enabled': _quietHoursEnabled,
              'quiet_hours_from': _quietHoursFrom,
              'quiet_hours_to': _quietHoursTo,
            }),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    await prefs.setString('server_ip', ip);
    await prefs.setString('jwt_token', jwtToken);
    await prefs.setString('secret_token', secret);
    await prefs.setString('pet_name', _petNameController.text.trim());
    await prefs.setString('language_code', _languageCode);
    await prefs.setString('pet_type', _petType);
    await prefs.setString('theme_mode', _themeModeString);
    await prefs.setBool('alerts_zone_enabled', _alertsZoneEnabled);
    await prefs.setBool('alerts_battery_enabled', _alertsBatteryEnabled);
    await prefs.setBool('alerts_sound_enabled', _alertsSoundEnabled);
    await prefs.setDouble('alerts_battery_threshold', _batteryThreshold);
    await prefs.setBool('quiet_hours_enabled', _quietHoursEnabled);
    await prefs.setInt('quiet_hours_from', _quietHoursFrom);
    await prefs.setInt('quiet_hours_to', _quietHoursTo);

    if (_profilePicBase64 != null) {
      await prefs.setString('profile_pic', _profilePicBase64!);
    } else {
      await prefs.remove('profile_pic');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      PetTrackApp.setLocale(context, Locale(_languageCode));

      ThemeMode newMode;
      switch (_themeModeString) {
        case 'light':
          newMode = ThemeMode.light;
          break;
        case 'dark':
          newMode = ThemeMode.dark;
          break;
        default:
          newMode = ThemeMode.system;
      }
      PetTrackApp.setThemeMode(context, newMode);

      if (widget.isSetup) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MainNavigationScreen(
                  serverIp: _ipController.text.trim(),
                  token: jwtToken,
                  petName: _petNameController.text.trim(),
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              petSaveFailed ? l10n.setupErrSave : l10n.saveSuccess,
            ),
            backgroundColor: petSaveFailed
                ? Theme.of(context).colorScheme.error
                : AppColors.primary,
          ),
        );
      }
    }
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfilePicture(AppLocalizations l10n) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          onLongPress: () {
            setState(() {
              _profilePicBase64 = null;
            });
          },
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.outline.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  color: AppColors.surfaceVariant,
                  image: _profilePicBase64 != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(_profilePicBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePicBase64 == null
                    ? const Icon(Icons.pets, size: 60, color: AppColors.primary)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.uploadProfilePicture,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildProfileCard(AppLocalizations l10n) {
    return _buildCard(l10n.profileAndSystem, [
      Text(l10n.petName, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextField(
        controller: _petNameController,
        decoration: InputDecoration(hintText: l10n.petNameHint),
      ),
      const SizedBox(height: 20),
      Text(l10n.petTypeTitle, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _petType,
            isExpanded: true,
            items: ['dog', 'cat', 'rabbit', 'guineapig', 'bird', 'other']
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(_getLocalizedPetType(context, type)),
                  ),
                )
                .toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _petType = newValue);
              }
            },
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _languageCode,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(l10n.languageEnglish),
                        ),
                        DropdownMenuItem(
                          value: 'hu',
                          child: Text(l10n.languageHungarian),
                        ),
                        DropdownMenuItem(
                          value: 'zh',
                          child: Text(
                            '${l10n.languageChinese} ${l10n.aiGeneratedMarker}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'it',
                          child: Text(
                            '${l10n.languageItalian} ${l10n.aiGeneratedMarker}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'de',
                          child: Text(
                            '${l10n.languageGerman} ${l10n.aiGeneratedMarker}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ja',
                          child: Text(
                            '${l10n.languageJapanese} ${l10n.aiGeneratedMarker}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ko',
                          child: Text(
                            '${l10n.languageKorean} ${l10n.aiGeneratedMarker}',
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) async {
                        if (newValue != null && newValue != _languageCode) {
                          setState(() => _languageCode = newValue);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('language_code', newValue);
                          if (mounted) {
                            PetTrackApp.setLocale(context, Locale(newValue));
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appearance,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _themeModeString,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(l10n.themeSystem),
                        ),
                        DropdownMenuItem(
                          value: 'light',
                          child: Text(l10n.themeLight),
                        ),
                        DropdownMenuItem(
                          value: 'dark',
                          child: Text(l10n.themeDark),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _themeModeString = newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildAlertsCard(AppLocalizations l10n) {
    return _buildCard(l10n.alertsTitle, [
      SwitchListTile(
        title: Text(l10n.alertsZone),
        value: _alertsZoneEnabled,
        onChanged: (val) => setState(() => _alertsZoneEnabled = val),
        contentPadding: EdgeInsets.zero,
      ),
      SwitchListTile(
        title: Text(l10n.alertsBattery),
        value: _alertsBatteryEnabled,
        onChanged: (val) => setState(() => _alertsBatteryEnabled = val),
        contentPadding: EdgeInsets.zero,
      ),
      SwitchListTile(
        title: Text(l10n.alertsSound),
        value: _alertsSoundEnabled,
        onChanged: (val) => setState(() => _alertsSoundEnabled = val),
        contentPadding: EdgeInsets.zero,
      ),
      if (_alertsBatteryEnabled) ...[
        const SizedBox(height: 8),
        Text(l10n.batteryThreshold(_batteryThreshold.toInt())),
        Slider(
          value: _batteryThreshold,
          min: 5,
          max: 50,
          divisions: 9,
          label: "${_batteryThreshold.toInt()}%",
          onChanged: (val) => setState(() => _batteryThreshold = val),
        ),
      ],
      const Divider(height: 32),
      SwitchListTile(
        title: Text(l10n.quietHoursTitle),
        subtitle: Text(l10n.quietHoursSubtitle),
        value: _quietHoursEnabled,
        onChanged: (val) => setState(() => _quietHoursEnabled = val),
        contentPadding: EdgeInsets.zero,
      ),
      if (_quietHoursEnabled) ...[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bedtime_outlined),
          title: Text(l10n.quietHoursFrom),
          trailing: Text(
            _formatMinutes(_quietHoursFrom),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () => _pickQuietTime(isFrom: true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.wb_sunny_outlined),
          title: Text(l10n.quietHoursTo),
          trailing: Text(
            _formatMinutes(_quietHoursTo),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () => _pickQuietTime(isFrom: false),
        ),
      ],
      const SizedBox(height: 16),
      Center(
        child: OutlinedButton.icon(
          onPressed: () async {
            final notifService = NotificationService();
            await notifService.requestPermissions();
            await notifService.showNotification(
              id: 999,
              title: l10n.testNotifTitle,
              body: l10n.testNotifBody,
              respectQuietHours: false,
            );
          },
          icon: const Icon(Icons.notifications_active),
          label: Text(l10n.testNotification),
        ),
      ),
      const Divider(height: 32),
      Text(
        l10n.alertsRemoteTitle,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(l10n.alertsRemoteDesc, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      Text(l10n.alertsRemoteUrlLabel, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextField(
        controller: _ntfyUrlController,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(hintText: l10n.alertsRemoteUrlHint),
      ),
      const SizedBox(height: 12),
      Text(
        l10n.alertsRemoteTokenLabel,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      TextField(controller: _ntfyTokenController, obscureText: true),
      const SizedBox(height: 12),
      Center(
        child: OutlinedButton.icon(
          onPressed: _testingNtfy ? null : () => _testRemoteAlert(l10n),
          icon: _testingNtfy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(l10n.alertsRemoteTest),
        ),
      ),
    ]);
  }

  /// Formats minutes-after-midnight as a 24h `HH:mm` clock label.
  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickQuietTime({required bool isFrom}) async {
    final current = isFrom ? _quietHoursFrom : _quietHoursTo;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isFrom) {
        _quietHoursFrom = minutes;
      } else {
        _quietHoursTo = minutes;
      }
    });
  }

  /// Push the remote-alert settings to the server, then ask it to send one
  /// test notification — proving the topic end to end before trusting it.
  Future<void> _testRemoteAlert(AppLocalizations l10n) async {
    final url = _ntfyUrlController.text.trim();
    if (url.isNotEmpty && !isValidNtfyUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.alertsRemoteUrlInvalid)),
      );
      return;
    }
    setState(() => _testingNtfy = true);
    final base = normalizeServerUrl(_ipController.text.trim());
    bool sent = false;
    try {
      final saveResponse = await http
          .post(
            Uri.parse('$base/api/settings'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-token': AuthService.token,
            },
            body: jsonEncode({
              'ntfy_url': url,
              'ntfy_token': _ntfyTokenController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (saveResponse.statusCode == 200) {
        final testResponse = await http
            .post(
              Uri.parse('$base/api/notify/test'),
              headers: AuthService.headers,
            )
            .timeout(const Duration(seconds: 6));
        sent = testResponse.statusCode == 200;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _testingNtfy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent ? l10n.alertsRemoteTestSent : l10n.alertsRemoteTestFailed,
        ),
      ),
    );
  }

  /// Fetches /api/version from the configured server and keeps the result
  /// for the About card's update check.
  Future<void> _checkServerVersion() async {
    final raw = _ipController.text.trim();
    if (raw.isEmpty) return;
    setState(() => _checkingVersion = true);
    final base = normalizeServerUrl(raw);
    String? version;
    try {
      final response = await http
          .get(Uri.parse('$base/api/version'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        version = data['version'] as String?;
      }
    } catch (e) {
      debugPrint('version check failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _serverVersion = version;
      _checkingVersion = false;
    });
  }

  /// The server's watchdog view plus its retention setting.
  Future<void> _fetchSystemHealth() async {
    final raw = _ipController.text.trim();
    if (raw.isEmpty || AuthService.token.isEmpty) return;
    final base = normalizeServerUrl(raw);
    try {
      final responses = await Future.wait([
        http
            .get(
              Uri.parse('$base/api/system-health'),
              headers: AuthService.headers,
            )
            .timeout(const Duration(seconds: 4)),
        http
            .get(
              Uri.parse('$base/api/settings'),
              headers: AuthService.headers,
            )
            .timeout(const Duration(seconds: 4)),
      ]);
      if (!mounted) return;
      final healthResponse = responses[0];
      final settingsResponse = responses[1];
      if (healthResponse.statusCode != 200) {
        setState(() => _healthFailed = true);
        return;
      }
      setState(() {
        _health = jsonDecode(healthResponse.body) as Map<String, dynamic>;
        _healthFailed = false;
        if (settingsResponse.statusCode == 200) {
          final settings =
              jsonDecode(settingsResponse.body) as Map<String, dynamic>;
          final days = settings['replay_retention_days'];
          if (days is int) _retentionDays = days;
          _ntfyUrlController.text = settings['ntfy_url'] as String? ?? '';
          _ntfyTokenController.text = settings['ntfy_token'] as String? ?? '';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _healthFailed = true);
    }
  }

  /// Change the replay retention on the server (it prunes accordingly).
  Future<void> _saveRetention(int days) async {
    final l10n = AppLocalizations.of(context)!;
    final previous = _retentionDays;
    setState(() => _retentionDays = days);
    try {
      final response = await http
          .post(
            Uri.parse(
              '${normalizeServerUrl(_ipController.text.trim())}/api/settings',
            ),
            headers: {
              'x-api-token': AuthService.token,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'replay_retention_days': days}),
          )
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.healthRetentionSaved)),
        );
      } else {
        setState(() => _retentionDays = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsSaveError)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _retentionDays = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSaveError)),
      );
    }
  }

  String _versionStatus(AppLocalizations l10n) {
    final server = _serverVersion;
    if (server == null) return l10n.versionUnknown;
    final cmp = compareVersions(kAppVersion, server);
    if (cmp == 0) return l10n.versionMatch;
    return cmp < 0 ? l10n.versionAppOlder : l10n.versionServerOlder;
  }

  Widget _versionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutCard(AppLocalizations l10n) {
    return _buildCard(l10n.aboutCardTitle, [
      _versionRow(l10n.versionAppLabel, kAppVersion),
      _versionRow(
        l10n.versionServerLabel,
        _serverVersion ?? l10n.versionUnknown,
      ),
      const SizedBox(height: 8),
      Text(_versionStatus(l10n), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      Center(
        child: OutlinedButton.icon(
          onPressed: _checkingVersion ? null : _checkServerVersion,
          icon: _checkingVersion
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.system_update),
          label: Text(l10n.versionCheckButton),
        ),
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () =>
                _showInfoDialog(l10n.privacyTitle, l10n.privacyBody),
            icon: const Icon(Icons.shield_outlined),
            label: Text(l10n.privacyButton),
          ),
          TextButton.icon(
            onPressed: () =>
                _showInfoDialog(l10n.whatsNewTitle, l10n.changelogBody),
            icon: const Icon(Icons.celebration_outlined),
            label: Text(l10n.whatsNewButton),
          ),
        ],
      ),
    ]);
  }

  /// The server's watchdog: camera alive, disk fine, replays under control.
  Widget _buildHealthCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final data = _health;
    final disk = data?['disk'] as Map<String, dynamic>? ?? const {};
    final diskLow = disk['low'] == true;
    final online = data?['camera_online'] == true;
    final quietSeconds = (data?['camera_quiet_seconds'] as num?)?.toDouble();
    final replays = data?['replays'] as Map<String, dynamic>? ?? const {};
    // The server's value may not be one of the pickable presets.
    final retentionChoices = {7, 14, 30, 90, _retentionDays}.toList()..sort();

    return _buildCard(l10n.healthCardTitle, [
      if (data == null && _healthFailed)
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.healthLoadError,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: _fetchSystemHealth,
              child: Text(l10n.retry),
            ),
          ],
        )
      else if (data == null)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        )
      else ...[
        _healthRow(
          icon: online ? Icons.videocam : Icons.videocam_off,
          iconColor: online ? AppColors.success : AppColors.warning,
          title: online ? l10n.healthCameraOnline : l10n.healthCameraOffline,
          caption: quietSeconds == null
              ? null
              : l10n.healthLastSeen(formatDurationSeconds(l10n, quietSeconds)),
        ),
        const SizedBox(height: 16),
        _healthRow(
          icon: diskLow ? Icons.warning_amber : Icons.storage_outlined,
          iconColor: diskLow
              ? AppColors.warning
              : theme.colorScheme.onSurfaceVariant,
          title: l10n.healthDiskFreeOf(
            formatBytes((disk['free_bytes'] as num? ?? 0).toInt()),
            formatBytes((disk['total_bytes'] as num? ?? 0).toInt()),
          ),
          caption: diskLow ? l10n.healthDiskLow : null,
          captionColor: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _healthRow(
          icon: Icons.movie_outlined,
          iconColor: theme.colorScheme.onSurfaceVariant,
          title: l10n.healthReplaysStored(
            (replays['count'] as num? ?? 0).toInt(),
            formatBytes((replays['bytes'] as num? ?? 0).toInt()),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.healthKeepReplays,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            DropdownButton<int>(
              value: _retentionDays,
              underline: const SizedBox.shrink(),
              items: [
                for (final days in retentionChoices)
                  DropdownMenuItem(
                    value: days,
                    child: Text(l10n.insightsRangeDays(days)),
                  ),
              ],
              onChanged: (days) {
                if (days != null && days != _retentionDays) {
                  _saveRetention(days);
                }
              },
            ),
          ],
        ),
      ],
    ]);
  }

  Widget _healthRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? caption,
    Color? captionColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyLarge),
              if (caption != null)
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: captionColor ?? theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonitorCard(AppLocalizations l10n) {
    return _buildCard(l10n.monitorAndConnection, [
      Text(l10n.serverIp, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextField(
        controller: _ipController,
        decoration: InputDecoration(hintText: l10n.serverIpHint),
      ),
      const SizedBox(height: 20),
      Text(l10n.secretToken, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextField(controller: _tokenController, obscureText: true),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.setupMonitorTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.settingsQrDialogDesc),
                    const SizedBox(height: 20),
                    Container(
                      width: 216,
                      height: 216,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: jsonEncode({
                          "ip": _normalizeHost(_ipController.text),
                          "secret": _tokenController.text,
                        }),
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.settingsQrDialogDone),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.qr_code),
          label: Text(l10n.settingsShowQrBtn),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: Text(l10n.settingsSignOutTitle),
                  content: Text(l10n.settingsSignOutMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.settingsSignOut),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              // Revoke the session on the server, forget it on this device.
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const BootScreen()),
                  (route) => false,
                );
              }
            }
          },
          icon: const Icon(Icons.logout),
          label: Text(l10n.settingsSignOut),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: Text(l10n.settingsResetConfirmTitle),
                  content: Text(l10n.settingsResetConfirmDesc),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        l10n.settingsResetApp,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const BootScreen()),
                  (route) => false,
                );
              }
            }
          },
          icon: const Icon(Icons.restore, color: Colors.redAccent),
          label: Text(
            l10n.settingsResetApp,
            style: const TextStyle(color: Colors.redAccent),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    ]);
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.save,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncToWatchButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.syncStarting)),
              );
              final success = await WearSyncService().sendCredentialsToWatch(
                _ipController.text,
                _tokenController.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? l10n.syncSuccess : l10n.syncNoWatch,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.watch, color: Colors.blueAccent),
            label: Text(
              l10n.syncToWatch,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.blueAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Desktop Layout
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsTitle,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildProfilePicture(l10n),
                              const SizedBox(height: 32),
                              _buildProfileCard(l10n),
                              _buildAlertsCard(l10n),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMonitorCard(l10n),
                              _buildHealthCard(l10n),
                              _buildAboutCard(l10n),
                              _buildSaveButton(l10n),
                              _buildSyncToWatchButton(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Mobile Layout
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l10n.settingsTitle,
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildProfilePicture(l10n),
                    const SizedBox(height: 40),
                    _buildProfileCard(l10n),
                    _buildAlertsCard(l10n),
                    _buildMonitorCard(l10n),
                    _buildHealthCard(l10n),
                    _buildAboutCard(l10n),
                    const SizedBox(height: 16),
                    _buildSaveButton(l10n),
                    _buildSyncToWatchButton(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
