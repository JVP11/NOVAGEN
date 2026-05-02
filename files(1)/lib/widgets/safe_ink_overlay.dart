import 'package:flutter/material.dart';

import '../app_theme.dart';

// ============================================================
// safe_ink_overlay.dart — three on-camera alignment guides
//
// White + black reference circles (dashed) and the large orange
// indicator ring (pulsing). Must stay visually in sync with the
// sampling coordinates in `safe_ink_analyzer.dart`.
// ============================================================

class SafeInkOverlay extends StatelessWidget {
  final Animation<double>? pulseScale;

  const SafeInkOverlay({super.key, this.pulseScale});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final double w = c.maxWidth;
        final double h = c.maxHeight;
        final double ring = (w * 0.62).clamp(200.0, 320.0);
        final double small = (w * 0.16).clamp(44.0, 72.0);

        Widget ringChild = Container(
          width: ring,
          height: ring,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kOrange, width: 3),
          ),
          alignment: Alignment.center,
          child: const Text(
            'COLOR RING',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        );

        if (pulseScale != null) {
          ringChild = AnimatedBuilder(
            animation: pulseScale!,
            builder: (context, child) => Transform.scale(
              scale: pulseScale!.value,
              child: child,
            ),
            child: ringChild,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // White reference — top-left (matches analyser ~0.22, 0.20)
            Positioned(
              left: w * 0.11,
              top: h * 0.12,
              child: _RefCircle(
                diameter: small,
                label: 'White ref',
                borderColor: Colors.white,
                dash: true,
              ),
            ),

            // Black reference — top-right (~0.78, 0.20)
            Positioned(
              right: w * 0.11,
              top: h * 0.12,
              child: _RefCircle(
                diameter: small,
                label: 'Black ref',
                borderColor: Colors.black87,
                fillHint: Colors.black26,
                dash: true,
              ),
            ),

            Center(child: ringChild),

            Positioned(
              left: 0,
              right: 0,
              bottom: h * 0.16,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Align all 3 zones, then tap Scan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RefCircle extends StatelessWidget {
  final double diameter;
  final String label;
  final Color borderColor;
  final Color? fillHint;
  final bool dash;

  const _RefCircle({
    required this.diameter,
    required this.label,
    required this.borderColor,
    this.fillHint,
    this.dash = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _DashedRingPainter(
            color: borderColor,
            dashed: dash,
            fillHint: fillHint,
          ),
          child: SizedBox(width: diameter, height: diameter),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  final Color? fillHint;

  _DashedRingPainter({
    required this.color,
    required this.dashed,
    this.fillHint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2 - 1.5;

    if (fillHint != null) {
      final Paint fill = Paint()..color = fillHint!;
      canvas.drawCircle(c, r, fill);
    }

    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;

    if (!dashed) {
      canvas.drawCircle(c, r, p);
      return;
    }

    const double dash = 8, gap = 6;
    final Path path = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dash;
        final Path extract = metric.extractPath(distance, next);
        canvas.drawPath(extract, p);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashed != dashed ||
      oldDelegate.fillHint != fillHint;
}
