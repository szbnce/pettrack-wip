import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/utils/pairing.dart';
import 'package:pettrack_app/utils/server_url.dart';
import 'package:pettrack_app/widgets/server_discovery_dialog.dart';
import '../services/auth_service.dart';
import 'qr_scanner_screen.dart';
import 'main_navigation.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  final _secureStorage = const FlutterSecureStorage();
  final _pinController = TextEditingController();
  final _ipController = TextEditingController();

  String? _serverIp;
  String? _secretToken;
  String? _jwtToken;

  final _nameController = TextEditingController();
  String _selectedType = 'dog';

  bool _isLoading = false;
  Timer? _monitorPollTimer;

  final List<String> _petTypes = [
    'dog',
    'cat',
    'rabbit',
    'guineapig',
    'bird',
    'other',
  ];

  String _getTranslatedType(String typeKey, AppLocalizations l10n) {
    switch (typeKey) {
      case 'dog':
        return l10n.petTypeDog;
      case 'cat':
        return l10n.petTypeCat;
      case 'rabbit':
        return l10n.petTypeRabbit;
      case 'guineapig':
        return l10n.petTypeGuineaPig;
      case 'bird':
        return l10n.petTypeBird;
      case 'other':
        return l10n.petTypeOther;
      default:
        return l10n.unknown;
    }
  }

  Future<void> _startQRscan() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QRScannerScreen()));
    // The scanner only hands over well-formed payloads; re-check anyway so
    // a bad map can never crash the login.
    final fields = pairingFields(result);
    if (fields != null) _processLogin(fields['ip']!, fields['secret']!);
  }

  Future<void> _startDemoMode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? wantDemo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.demoModeTitle),
        content: Text(l10n.demoModePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (wantDemo == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', 'demo_ip');
      await prefs.setString('jwt_token', 'demo_token');
      await prefs.setString('pet_name', 'Demo Pet');
      await prefs.setString('app_mode', 'client');
      await _secureStorage.write(key: 'demo_pin', value: '8068');

      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(
            serverIp: 'demo_ip',
            token: 'demo_token',
            petName: 'Demo Pet',
          ),
        ),
      );
    }
  }

  Future<void> _handlePinSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    final ipInput = _ipController.text.trim();
    if (pin.isEmpty || ipInput.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.setupMissingFields)));
      return;
    }

    // Demo logic moved to _startDemoMode()

    final targetIp = normalizeServerUrl(ipInput);

    _ipController.text = targetIp;

    setState(() => _isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse('$targetIp/api/auth/login_pin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'pin': pin}),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Register the session so the short-lived access token can rotate.
        await AuthService.saveSession(
          accessToken: data['token'],
          refreshToken: data['refresh_token'] ?? '',
          expiresInSeconds: (data['expires_in'] as num?)?.toInt() ?? 3600,
          role: 'viewer',
        );

        // Try to fetch existing pet data to avoid re-entering
        try {
          final petRes = await http
              .get(
                Uri.parse('$targetIp/api/pet'),
                headers: {'x-api-token': data['secret']},
              )
              .timeout(const Duration(seconds: 3));

          if (petRes.statusCode == 200) {
            final petData = jsonDecode(petRes.body);
            if (petData['name'] != null && petData['name'] != 'Unknown') {
              _nameController.text = petData['name'];
              String typeVal = (petData['type'] ?? 'dog')
                  .toString()
                  .toLowerCase();
              if (typeVal.startsWith('pettype')) {
                typeVal = typeVal.replaceFirst('pettype', '');
              }
              _selectedType = typeVal;

              // We have an existing pet! Skip the rest of the wizard.
              setState(() {
                _serverIp = targetIp;
                _secretToken = data['secret'];
                _jwtToken = data['secret'];
              });
              await _secureStorage.write(
                key: 'secret_token',
                value: _secretToken!,
              );

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('server_ip', _serverIp!);
              await prefs.setString('secret_token', _secretToken!);
              await prefs.setString('jwt_token', _jwtToken!);
              await prefs.setString('pet_name', _nameController.text.trim());
              await prefs.setString('pet_type', _selectedType);
              await prefs.setBool('is_setup_completed', true);

              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MainNavigationScreen(
                      serverIp: _serverIp!,
                      token: _jwtToken!,
                      petName: _nameController.text,
                    ),
                  ),
                );
              }
              return; // Exit here, we are done!
            }
          }
        } catch (_) {
          // Ignore errors, just proceed with empty fields
        }

        setState(() {
          _serverIp = targetIp;
          _secretToken = data['secret'];
          _jwtToken = data['secret']; // Note: matching web logic for token
          _isLoading = false;
        });

        await _secureStorage.write(key: 'secret_token', value: _secretToken!);

        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // The server answered and said no — wrong PIN, not a network wobble.
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.setupErrPin)));
        }
      }
    } catch (e) {
      // Reachable-but-refused and unreachable look alike from here.
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.setupErrConnect)));
      }
    }
  }

  Future<void> _processLogin(String ip, String secret) async {
    final l10n = AppLocalizations.of(context)!;
    // QR payloads may hold "host:port" (server terminal) or a full URL
    // (in-app QR) — normalize so both work.
    ip = normalizeServerUrl(ip);
    setState(() => _isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse('$ip/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'secret': secret}),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Register the session so the short-lived access token can rotate.
        await AuthService.saveSession(
          accessToken: data['token'],
          refreshToken: data['refresh_token'] ?? '',
          expiresInSeconds: (data['expires_in'] as num?)?.toInt() ?? 3600,
          role: 'viewer',
        );

        // Try to fetch existing pet data to avoid re-entering
        try {
          final petRes = await http
              .get(
                Uri.parse('$ip/api/pet'),
                headers: {'x-api-token': data['token']},
              )
              .timeout(const Duration(seconds: 3));

          if (petRes.statusCode == 200) {
            final petData = jsonDecode(petRes.body);
            if (petData['name'] != null && petData['name'] != 'Unknown') {
              _nameController.text = petData['name'];
              String typeVal = (petData['type'] ?? 'dog')
                  .toString()
                  .toLowerCase();
              if (typeVal.startsWith('pettype')) {
                typeVal = typeVal.replaceFirst('pettype', '');
              }
              _selectedType = typeVal;

              // We have an existing pet! Skip the rest of the wizard.
              setState(() {
                _serverIp = ip;
                _secretToken = secret;
                _jwtToken = data['token'];
              });
              await _secureStorage.write(key: 'secret_token', value: secret);

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('server_ip', _serverIp!);
              await prefs.setString('secret_token', _secretToken!);
              await prefs.setString('jwt_token', _jwtToken!);
              await prefs.setString('pet_name', _nameController.text.trim());
              await prefs.setString('pet_type', _selectedType);
              await prefs.setBool('is_setup_completed', true);

              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MainNavigationScreen(
                      serverIp: _serverIp!,
                      token: _jwtToken!,
                      petName: _nameController.text,
                    ),
                  ),
                );
              }
              return; // Exit here, we are done!
            }
          }
        } catch (_) {
          // Ignore errors, just proceed with empty fields
        }

        setState(() {
          _serverIp = ip;
          _secretToken = secret;
          _jwtToken = data['token'];
          _isLoading = false;
        });

        await _secureStorage.write(key: 'secret_token', value: secret);

        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // A QR can outlive the secret it carries — say so instead of
        // blaming the network.
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.invalidSecretToken)));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.setupErrConnect)));
      }
    }
  }

  void _dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _ipController.dispose();
  }

  Future<void> _finishSetup() async {
    final l10n = AppLocalizations.of(context)!;

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.setupErrEmpty)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('$_serverIp/api/pet'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-token': _jwtToken!,
            },
            body: jsonEncode({
              'name': _nameController.text,
              'type': _selectedType,
            }),
          )
          .timeout(const Duration(seconds: 4));
      // A save that the server refused is a failed save — never finish the
      // wizard on top of it and pretend the pet was stored.
      if (response.statusCode != 200) {
        throw Exception('pet save failed: HTTP ${response.statusCode}');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', _serverIp!);
      await prefs.setString('secret_token', _secretToken!);
      await prefs.setString('jwt_token', _jwtToken!);
      await prefs.setString('pet_name', _nameController.text.trim());
      await prefs.setString('pet_type', _selectedType);

      if (mounted) {
        setState(() => _isLoading = false);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startMonitorPolling();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.setupErrSave)));
      }
    }
  }

  /// A monitor is optional hardware — no monitor yet is a valid state, not a
  /// wizard that never ends. Cancel the wait and go live.
  Future<void> _skipMonitorWait() async {
    _monitorPollTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_setup_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(
          serverIp: _serverIp!,
          token: _jwtToken!,
          petName: _nameController.text,
        ),
      ),
    );
  }

  void _startMonitorPolling() {
    _monitorPollTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      try {
        final response = await http
            .get(
              Uri.parse('$_serverIp/api/status'),
              headers: {'x-api-token': _jwtToken!},
            )
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['monitor_online'] == true) {
            timer.cancel();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_setup_completed', true);

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MainNavigationScreen(
                    serverIp: _serverIp!,
                    token: _jwtToken!,
                    petName: _nameController.text,
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        // ignore
      }
    });
  }

  @override
  void dispose() {
    _monitorPollTimer?.cancel();
    _pageController.dispose();
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPage(
              title: l10n.setupWelcomeTitle,
              description: l10n.setupWelcomeDesc,
              icon: Icons.qr_code_scanner,
              child: Column(
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: l10n.serverIp,
                      hintText: l10n.serverIpHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServerDiscoveryButton(
                    onSelected: (address) {
                      _ipController.text = normalizeServerUrl(address);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pinController,
                    decoration: InputDecoration(
                      labelText: l10n.enterPin,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                  ),
                  ElevatedButton(
                    onPressed: _handlePinSubmit,
                    child: Text(l10n.submitPin),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _startDemoMode(context),
                    icon: const Icon(Icons.play_circle_fill),
                    label: Text(l10n.demoModeBtn),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.orSeparator),
                ],
              ),
              actionButton: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _startQRscan,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        l10n.setupScanBtn,
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
            ),

            _buildPage(
              title: l10n.setupSuccessTitle,
              description: l10n.setupSuccessDesc,
              icon: Icons.pets,
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.petName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: l10n.petTypeTitle,
                      border: const OutlineInputBorder(),
                    ),
                    items: _petTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_getTranslatedType(value, l10n)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedType = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actionButton: ElevatedButton(
                onPressed: _finishSetup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: Text(
                  l10n.setupNextBtn,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            _buildPage(
              title: l10n.setupMonitorTitle,
              description: l10n.setupMonitorDesc,
              icon: Icons.camera_indoor,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: jsonEncode({
                    "ip": "$_serverIp",
                    "secret": _secretToken,
                  }),
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              actionButton: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _skipMonitorWait,
                    child: Text(l10n.setupSkipMonitor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData icon,
    required Widget actionButton,
    Widget? child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // ignore: use_null_aware_elements
          if (child != null) child,
          if (child != null) const SizedBox(height: 32),
          actionButton,
        ],
      ),
    );
  }
}
