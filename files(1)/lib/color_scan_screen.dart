// ============================================================
// color_scan_screen.dart — dedicated SafeInk capture lane
//
// Identical optics to the second tab inside [ScannerScreen],
// launched after barcode lookup when the shopper is ready to
// read the colour-changing ring.
// ============================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'models/scan_record.dart';
import 'result_screen.dart';
import 'utils/color_utils.dart';
import 'widgets/safe_ink_scanner_view.dart';

class ColorScanScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  final ScanRecord record;

  const ColorScanScreen({
    super.key,
    required this.cameras,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('SafeInk colour scan'),
        foregroundColor: Colors.white,
      ),
      body: SafeInkScannerView(
        cameras: cameras,
        onOutcome: (ColorScanOutcome outcome) async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'result'),
              builder: (_) => ResultScreen(
                scanRecord: record,
                outcome: outcome,
              ),
            ),
          );
        },
      ),
    );
  }
}
