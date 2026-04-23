import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrDisposalView extends StatefulWidget {
  const QrDisposalView({super.key});

  @override
  State<QrDisposalView> createState() => _QrDisposalViewState();
}

class _QrDisposalViewState extends State<QrDisposalView> {
  bool _handled = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _handled = true;
        Navigator.pop(context, rawValue.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Disposal QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleDetection,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black.withAlpha((0.55 * 255).round()),
              child: const Text(
                'Point the camera at the QR code on the disposal box.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
