import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../utils/color_utils.dart';
import '../utils/safe_ink_analyzer.dart';
import 'safe_ink_overlay.dart';

// ============================================================
// safe_ink_scanner_view.dart — preview + overlays + analyse
//
// Parents supply [onOutcome] once bytes are analysed so they can
// decide navigation (standalone colour flow vs in-app tab flow).
// ============================================================

typedef SafeInkOutcomeHandler = Future<void> Function(ColorScanOutcome outcome);

class SafeInkScannerView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final SafeInkOutcomeHandler onOutcome;

  const SafeInkScannerView({
    super.key,
    required this.cameras,
    required this.onOutcome,
  });

  @override
  State<SafeInkScannerView> createState() => _SafeInkScannerViewState();

  /// Convenience for screens that manage their own [CameraController].
  static Future<ColorScanOutcome> analyzeCapturedBytes(Uint8List bytes) =>
      analyzeSafeInkPhoto(bytes);
}

class _SafeInkScannerViewState extends State<SafeInkScannerView>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _initialised = false;
  bool _busy = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _primeCamera();
  }

  Future<void> _primeCamera() async {
    if (widget.cameras.isEmpty) return;

    final cam = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller = cam;

    try {
      await cam.initialize();
      if (mounted) setState(() => _initialised = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanNow() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _busy) return;

    setState(() => _busy = true);

    try {
      final snap = await ctrl.takePicture();
      final Uint8List bytes = await snap.readAsBytes();
      final outcome = await analyzeSafeInkPhoto(bytes);
      await widget.onOutcome(outcome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not analyse image: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      return const Center(
        child: Text(
          'No camera detected on this device.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (!_initialised || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: kBlue));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(153),
                ],
              ),
            ),
          ),
        ),
        SafeInkOverlay(pulseScale: _pulse),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _busy ? null : _scanNow,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _busy ? kSlate.withAlpha(204) : kOrange,
                        boxShadow: _busy
                            ? []
                            : [
                                BoxShadow(
                                  color: kOrange.withAlpha(153),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt,
                              color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _busy ? 'Analysing…' : 'TAP TO SCAN',
                    style: TextStyle(
                      color: _busy ? Colors.white38 : Colors.white54,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
