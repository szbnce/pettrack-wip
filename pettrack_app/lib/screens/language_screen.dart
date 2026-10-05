import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/main.dart';
import 'package:pettrack_app/screens/welcome_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);

    if (!context.mounted) return;

    PetTrackApp.setLocale(context, Locale(code));

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chooseLanguageTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildLangButton(
                        context,
                        'hu',
                        l10n.languageHungarian,
                        colorScheme.primary,
                        colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 16),
                      _buildLangButton(
                        context,
                        'en',
                        l10n.languageEnglish,
                        colorScheme.secondary,
                        colorScheme.onSecondary,
                      ),
                      const SizedBox(height: 16),
                      _buildLangButton(
                        context,
                        'zh',
                        '${l10n.languageChinese} ${l10n.aiGeneratedMarker}',
                        Colors.orange.shade700,
                        Colors.white,
                      ),
                      const SizedBox(height: 16),
                      _buildLangButton(
                        context,
                        'it',
                        '${l10n.languageItalian} ${l10n.aiGeneratedMarker}',
                        Colors.green.shade700,
                        Colors.white,
                      ),
                      const SizedBox(height: 16),
                      _buildLangButton(
                        context,
                        'de',
                        '${l10n.languageGerman} ${l10n.aiGeneratedMarker}',
                        Colors.blue.shade700,
                        Colors.white,
                      ),
                      const SizedBox(height: 16),
                      _buildLangButton(
                        context,
                        'ja',
                        '${l10n.languageJapanese} ${l10n.aiGeneratedMarker}',
                        Colors.purple.shade700,
                        Colors.white,
                      ),
                      const SizedBox(height: 16),
                      _buildLangButton(
                        context,
                        'ko',
                        '${l10n.languageKorean} ${l10n.aiGeneratedMarker}',
                        Colors.red.shade700,
                        Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(
    BuildContext context,
    String code,
    String label,
    Color bg,
    Color fg,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _selectLanguage(context, code),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
