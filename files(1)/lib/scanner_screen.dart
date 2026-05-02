// ============================================================
// scanner_screen.dart — Barcode + SafeInk colour (tabbed hub)
//
// Tab 1 wraps [MobileScanner] for product codes. Tab 2 reuses the
// shared [SafeInkScannerView] for the three-zone indicator capture.
// ============================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'app_theme.dart';
import 'barcode_result_screen.dart';
import 'models/scan_record.dart';
import 'result_screen.dart';
import 'utils/color_utils.dart';
import 'widgets/safe_ink_scanner_view.dart';

class ScannerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScannerScreen({super.key, required this.cameras});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  late ScanRecord _session;

  @override
  void initState() {
    super.initState();
    _session = ScanRecord.empty();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _goBarcodeResult(String code, String formatLabel) {
    final next = _session.copyWith(barcode: code);
    setState(() => _session = next);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BarcodeResultScreen(
          barcode: code,
          formatLabel: formatLabel,
          scanRecord: next,
          cameras: widget.cameras,
        ),
      ),
    );
  }

  Future<void> _onColorOutcome(ColorScanOutcome outcome) async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'result'),
        builder: (_) => ResultScreen(
          scanRecord: _session,
          outcome: outcome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'NovaGen Scanner',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: kOrange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Barcode'),
            Tab(text: 'SafeInk Color'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BarcodeScannerPane(
            onScanned: _goBarcodeResult,
            onPickSafeInkTab: () => _tabs.animateTo(1),
          ),
          SafeInkScannerView(
            cameras: widget.cameras,
            onOutcome: _onColorOutcome,
          ),
        ],
      ),
    );
  }
}

// ── Barcode / QR tab ─────────────────────────────────────────

enum _BarcodePillMode { linear, qr }

class _BarcodeScannerPane extends StatefulWidget {
  final void Function(String code, String formatLabel) onScanned;
  final VoidCallback onPickSafeInkTab;

  const _BarcodeScannerPane({
    required this.onScanned,
    required this.onPickSafeInkTab,
  });

  @override
  State<_BarcodeScannerPane> createState() => _BarcodeScannerPaneState();
}

class _BarcodeScannerPaneState extends State<_BarcodeScannerPane>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  _BarcodePillMode _mode = _BarcodePillMode.linear;
  bool _navLock = false;
  DateTime _lastFire = DateTime.fromMillisecondsSinceEpoch(0);

  late AnimationController _lineCtrl;

  static List<BarcodeFormat> _formatsFor(_BarcodePillMode m) {
    switch (m) {
      case _BarcodePillMode.linear:
        return const <BarcodeFormat>[
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.itf,
        ];
      case _BarcodePillMode.qr:
        return const <BarcodeFormat>[BarcodeFormat.qrCode];
    }
  }

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _spawnController(_mode);
  }

  void _spawnController(_BarcodePillMode mode) {
    _controller?.dispose();
    final List<BarcodeFormat> formats = _formatsFor(mode);
    _controller = MobileScannerController(
      formats: formats,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_navLock) return;

    final now = DateTime.now();
    if (now.difference(_lastFire).inMilliseconds < 900) return;

    Barcode? barcode;
    for (final b in capture.barcodes) {
      final String? raw = b.rawValue;
      if (raw != null && raw.isNotEmpty) {
        barcode = b;
        break;
      }
    }
    if (barcode == null) return;
    final String raw = barcode.rawValue!;

    _lastFire = now;
    _navLock = true;
    widget.onScanned(raw, barcode.format.name);
    Future<void>.delayed(const Duration(milliseconds: 800)).then((_) {
      _navLock = false;
    });
  }

  Future<void> _manualBarcode(BuildContext ctx) async {
    final ctl = TextEditingController();
    final String? typed = await showDialog<String>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: kDarkBlue,
        title: const Text('Manual barcode'),
        content: TextField(
          controller: ctl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Digits on pack',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kOrange),
            onPressed: () =>
                Navigator.pop(c, ctl.text.replaceAll(RegExp(r'\s+'), '')),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (typed != null && typed.length >= 4) {
      widget.onScanned(typed, 'Manual');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator(color: kBlue));
    }

    final MobileScannerController c = _controller!;

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: c,
          onDetect: _onDetect,
        ),
        AnimatedBuilder(
          animation: _lineCtrl,
          builder: (ctx, _) {
            return Stack(
              children: [
                CustomPaint(painter: _CornerBracketsPainter(), child: const SizedBox.expand()),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 100, 32, 200),
                    child: Align(
                      alignment: Alignment(0, -1 + _lineCtrl.value * 2),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: kOrange,
                          boxShadow: [
                            BoxShadow(
                              color: kOrange.withAlpha(128),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Align barcode within frame',
                    style: TextStyle(color: Colors.white70, shadows: [
                      Shadow(color: Colors.black, blurRadius: 6),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSlate,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => c.toggleTorch(),
                        child: const Icon(Icons.flashlight_on_rounded),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _manualBarcode(context),
                        child: const Text('Enter Manual'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill('Barcode', _BarcodePillMode.linear, _mode, (m) {
                        setState(() {
                          _mode = m;
                          _spawnController(m);
                        });
                      }),
                      _pill('QR Code', _BarcodePillMode.qr, _mode, (m) {
                        setState(() {
                          _mode = m;
                          _spawnController(m);
                        });
                      }),
                      GestureDetector(
                        onTap: widget.onPickSafeInkTab,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: kDarkBlue,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: kOrange),
                          ),
                          child: const Text(
                            'SafeInk',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(
    String label,
    _BarcodePillMode value,
    _BarcodePillMode current,
    void Function(_BarcodePillMode) onTap,
  ) {
    final bool on = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? kOrange : kDarkBlue,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? kOrange : kSlate),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: on ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = kOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double inset = 48;
    const double len = 38;
    final Rect r = Rect.fromLTRB(inset, 120, size.width - inset, size.height - 220);

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + len)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left + len, r.top),
      p,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(r.right - len, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + len),
      p,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.bottom - len)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.left + len, r.bottom),
      p,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(r.right - len, r.bottom)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.right, r.bottom - len),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
