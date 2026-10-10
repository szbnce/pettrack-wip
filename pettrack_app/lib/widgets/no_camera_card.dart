import 'package:flutter/material.dart';

/// The camera card when the server is up but no monitor has checked in.
///
/// This is the screen people land on after "Skip for now" in the wizard.
/// It used to be a spinner that never ended — the one dead end the first
/// run must not have — so it names the next step and hands over the
/// pairing code to do it with. Strings arrive already translated; this
/// widget has no l10n of its own.
class NoCameraCard extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onShowQr;

  const NoCameraCard({
    super.key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 56, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onShowQr,
              icon: const Icon(Icons.qr_code),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
