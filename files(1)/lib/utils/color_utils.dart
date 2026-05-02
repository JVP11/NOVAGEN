import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================
// color_utils.dart — RGB → HSV + SafeInk classification
//
// We normalise against white/black reference patches first, then
// classify using HSV so lighting changes affect us less.
// ============================================================

/// Result of analysing the SafeInk indicator (after normalisation).
class ColorScanOutcome {
  final Color displayColor;
  final String hexCode;
  final String status; // safe | moderate | unsafe
  final int safetyPercent;
  final String message;
  final double hue;
  final double saturation;
  final double value;

  const ColorScanOutcome({
    required this.displayColor,
    required this.hexCode,
    required this.status,
    required this.safetyPercent,
    required this.message,
    required this.hue,
    required this.saturation,
    required this.value,
  });
}

Map<String, double> rgbToHsv(int r, int g, int b) {
  final double rf = r / 255.0, gf = g / 255.0, bf = b / 255.0;
  double max = math.max(rf, math.max(gf, bf));
  double min = math.min(rf, math.min(gf, bf));
  double delta = max - min;
  double h = 0, s = 0;
  final double v = max;
  if (delta != 0) {
    s = delta / max;
    if (max == rf) {
      h = 60 * (((gf - bf) / delta) % 6);
    } else if (max == gf) {
      h = 60 * (((bf - rf) / delta) + 2);
    } else {
      h = 60 * (((rf - gf) / delta) + 4);
    }
    if (h < 0) h += 360;
  }
  return {'h': h, 's': s, 'v': v};
}

int _clamp255(num v) => v.round().clamp(0, 255);

/// Normalise one channel using black/white references.
int normaliseChannel(int raw, int black, int white) {
  final int denom = (white - black).abs();
  if (denom < 12) {
    // References are unreliable — fall back to raw stretch.
    return _clamp255(raw);
  }
  final double n = (raw - black) / denom * 255.0;
  return _clamp255(n);
}

String _hexFromRgb(int r, int g, int b) {
  String h2(int x) => x.toRadixString(16).padLeft(2, '0');
  return '#${h2(r)}${h2(g)}${h2(b)}'.toUpperCase();
}

ColorScanOutcome classifyNormalisedHsv({
  required int nr,
  required int ng,
  required int nb,
}) {
  final hsv = rgbToHsv(nr, ng, nb);
  final double h = hsv['h']!;
  final double s = hsv['s']!;
  final double v = hsv['v']!;

  final display = Color.fromARGB(255, nr, ng, nb);
  final hex = _hexFromRgb(nr, ng, nb);

  // Too dark — treat as unreliable / unsafe edge.
  if (v <= 0.20) {
    return ColorScanOutcome(
      displayColor: display,
      hexCode: hex,
      status: 'unsafe',
      safetyPercent: 12,
      message: 'Reading too dark — improve lighting and rescan',
      hue: h,
      saturation: s,
      value: v,
    );
  }

  // Low saturation → grey / brown → unsafe bucket.
  if (s < 0.15) {
    final pct = (8 + (v * 18).round()).clamp(5, 34);
    return ColorScanOutcome(
      displayColor: display,
      hexCode: hex,
      status: 'unsafe',
      safetyPercent: pct,
      message: 'Indicator reads neutral / brown — do not eat',
      hue: h,
      saturation: s,
      value: v,
    );
  }

  // Blue — safe band.
  if (h >= 180 && h <= 260 && s > 0.30 && v > 0.20) {
    final t = (h - 180) / (260 - 180);
    final pct = (70 + t * 29).round().clamp(70, 99);
    return ColorScanOutcome(
      displayColor: display,
      hexCode: hex,
      status: 'safe',
      safetyPercent: pct,
      message: 'Safe to eat',
      hue: h,
      saturation: s,
      value: v,
    );
  }

  // Green — moderate band.
  if (h >= 80 && h <= 179 && s > 0.25 && v > 0.20) {
    final t = (h - 80) / (179 - 80);
    final pct = (35 + t * 34).round().clamp(35, 69);
    return ColorScanOutcome(
      displayColor: display,
      hexCode: hex,
      status: 'moderate',
      safetyPercent: pct,
      message: 'Consume within 24 hours',
      hue: h,
      saturation: s,
      value: v,
    );
  }

  // Yellow / orange / red / magenta — triggered indicator.
  final pct = (10 + ((1.0 - s) * 24).round()).clamp(5, 34);
  return ColorScanOutcome(
    displayColor: display,
    hexCode: hex,
    status: 'unsafe',
    safetyPercent: pct,
    message: 'Do not consume',
    hue: h,
    saturation: s,
    value: v,
  );
}
