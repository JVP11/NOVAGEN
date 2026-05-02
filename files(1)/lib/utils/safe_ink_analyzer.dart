import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'color_utils.dart';

// ============================================================
// safe_ink_analyzer.dart — decode JPEG/PNG bytes + sample 3 circles
//
// Positions mirror the portrait overlay (white top-left,
// black top-right, indicator ring centred).
// ============================================================

const int _decodeTargetWidth = 480;

/// Normalised centre (x, y) and radius as fraction of min(w, h).
class CircleSampleSpec {
  final double cx;
  final double cy;
  final double radiusNorm;

  const CircleSampleSpec({
    required this.cx,
    required this.cy,
    required this.radiusNorm,
  });
}

/// Default layout matching `SafeInkOverlay` / `ColorScanScreen`.
const CircleSampleSpec kWhiteRefSpec = CircleSampleSpec(
  cx: 0.22,
  cy: 0.20,
  radiusNorm: 0.075,
);
const CircleSampleSpec kBlackRefSpec = CircleSampleSpec(
  cx: 0.78,
  cy: 0.20,
  radiusNorm: 0.075,
);
const CircleSampleSpec kColorRingSpec = CircleSampleSpec(
  cx: 0.50,
  cy: 0.52,
  radiusNorm: 0.20,
);

(int, int, int) _averageRgbInCircle(
  Uint8List rgba,
  int width,
  int height,
  CircleSampleSpec spec, {
  int step = 4,
}) {
  final int minDim = width < height ? width : height;
  final double radiusPx = spec.radiusNorm * minDim;
  final double cx = spec.cx * width;
  final double cy = spec.cy * height;

  int rSum = 0, gSum = 0, bSum = 0, n = 0;

  final int x0 = (cx - radiusPx).floor().clamp(0, width - 1);
  final int x1 = (cx + radiusPx).ceil().clamp(0, width - 1);
  final int y0 = (cy - radiusPx).floor().clamp(0, height - 1);
  final int y1 = (cy + radiusPx).ceil().clamp(0, height - 1);

  final double r2 = radiusPx * radiusPx;

  for (int y = y0; y <= y1; y += step) {
    for (int x = x0; x <= x1; x += step) {
      final double dx = x - cx;
      final double dy = y - cy;
      if (dx * dx + dy * dy > r2) continue;

      final int idx = (y * width + x) * 4;
      if (idx + 2 >= rgba.length) continue;
      rSum += rgba[idx];
      gSum += rgba[idx + 1];
      bSum += rgba[idx + 2];
      n++;
    }
  }

  if (n == 0) {
    return (128, 128, 128);
  }

  return (rSum ~/ n, gSum ~/ n, bSum ~/ n);
}

/// Full pipeline: decode → sample references → normalise → HSV classify.
Future<ColorScanOutcome> analyzeSafeInkPhoto(Uint8List bytes) async {
  final ui.Codec codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: _decodeTargetWidth,
  );
  final ui.FrameInfo frame = await codec.getNextFrame();
  final ui.Image image = frame.image;
  final int w = image.width;
  final int h = image.height;

  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  codec.dispose();

  if (data == null) {
    return const ColorScanOutcome(
      displayColor: Color(0xFF808080),
      hexCode: '#808080',
      status: 'unsafe',
      safetyPercent: 10,
      message: 'Could not read image pixels',
      hue: 0,
      saturation: 0,
      value: 0,
    );
  }

  final Uint8List rgba = data.buffer.asUint8List();

  final (wr, wg, wb) = _averageRgbInCircle(rgba, w, h, kWhiteRefSpec);
  final (br, bg, bb) = _averageRgbInCircle(rgba, w, h, kBlackRefSpec);
  final (rr, rg, rb) = _averageRgbInCircle(rgba, w, h, kColorRingSpec);

  final int nr = normaliseChannel(rr, br, wr);
  final int ng = normaliseChannel(rg, bg, wg);
  final int nb = normaliseChannel(rb, bb, wb);

  return classifyNormalisedHsv(nr: nr, ng: ng, nb: nb);
}
