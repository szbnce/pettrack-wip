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
                  l10n.qrScannerHint,
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
