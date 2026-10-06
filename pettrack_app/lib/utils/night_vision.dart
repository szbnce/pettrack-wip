import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Gamma used for the night lift: > 1 brightens shadows while keeping
/// highlights roughly in place.
const double kNightGamma = 1.8;

/// Lifts shadows on dark frames so the pet is visible at night.
///
/// A lookup table applies the classic gamma curve
/// `out = 255 * (in / 255)^(1/gamma)` to the RGB channels; alpha is kept.
img.Image applyNightBoost(img.Image frame, {double gamma = kNightGamma}) {
  final lut = List<int>.generate(256, (i) {
    final v = math.pow(i / 255.0, 1.0 / gamma) * 255.0;
    return v.round().clamp(0, 255);
  });

  for (final pixel in frame) {
    pixel.r = lut[pixel.r.toInt()];
    pixel.g = lut[pixel.g.toInt()];
    pixel.b = lut[pixel.b.toInt()];
  }
  return frame;
}
