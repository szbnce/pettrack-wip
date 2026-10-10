import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/utils/pairing.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  // A code that is not ours used to be ignored without a word, which reads
  // as "the camera is broken". Say what happened instead.
  bool _rejectedCode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrScannerTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // The bar floats over a live camera feed, whose frame is dark more
        // often than not — white icons in both themes.
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue == null) continue;
                final data = parsePairingPayload(rawValue);
                if (data != null) {
                  _hasScanned = true;
                  Navigator.of(context).pop(data);
                  break;
                }
              }
              // Every barcode in the frame was something else — say so
              // rather than leaving a green frame and silence.
              if (!_hasScanned && !_rejectedCode && barcodes.isNotEmpty) {
                setState(() => _rejectedCode = true);
              }
            },
            errorBuilder: (context, error) {
              final denied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return _ScannerProblem(
                message: denied
                    ? l10n.qrScannerCameraDenied
                    : l10n.qrScannerCameraBroken,
                buttonLabel: l10n.qrScannerGoBack,
              );
            },
          ),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _rejectedCode ? l10n.qrScannerNotOurs : l10n.qrScannerHint,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// When the camera cannot run at all, say why and give the way out.
///
/// A black preview with a green frame is the worst possible answer to
/// "why is nothing happening" on the one screen that pairs the phone.
class _ScannerProblem extends StatelessWidget {
  final String message;
  final String buttonLabel;

  const _ScannerProblem({required this.message, required this.buttonLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
