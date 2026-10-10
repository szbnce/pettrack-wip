import 'package:flutter/material.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'main_navigation.dart';
import 'setup_wizard_screen.dart';

/// Boot, when the phone is already set up but the server cannot be reached.
///
/// This used to fall through to the setup wizard with no explanation — a
/// paired phone being told to pair again is the same as losing the setup.
/// The session is not the problem here, the network is, so the answer is
/// "try again" with an explicit way to start over if that is what is meant.
class ServerRecoveryScreen extends StatefulWidget {
  final String serverIp;

  const ServerRecoveryScreen({super.key, required this.serverIp});

  @override
  State<ServerRecoveryScreen> createState() => _ServerRecoveryScreenState();
}

class _ServerRecoveryScreenState extends State<ServerRecoveryScreen> {
  bool _trying = false;

  Future<void> _retry() async {
    setState(() => _trying = true);
    final prefs = await SharedPreferences.getInstance();
    final ok = await AuthService.loginWithSecret(
      serverIp: widget.serverIp,
      secret: prefs.getString('secret_token') ?? '',
    );
    if (!mounted) return;
    setState(() => _trying = false);
    if (ok) {
      final petName = prefs.getString('pet_name') ?? '';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(
            serverIp: widget.serverIp,
            token: AuthService.token,
            petName: petName,
          ),
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.recoveryStillUnreachable)));
  }

  Future<void> _startOver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expires_at');
    await prefs.remove('secret_token');
    await prefs.remove('server_ip');
    await prefs.remove('pet_name');
    await prefs.remove('pet_type');
    await prefs.setBool('is_setup_completed', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SetupWizardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                l10n.recoveryTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.recoveryBody,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                widget.serverIp,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _trying ? null : _retry,
                icon: _trying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(l10n.recoveryRetry),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _trying ? null : _startOver,
                child: Text(l10n.recoveryStartOver),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
