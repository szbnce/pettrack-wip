import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pettrack_app/utils/night_vision.dart';

img.Image _solid(num value) {
  final frame = img.Image(width: 4, height: 4);
  img.fill(frame, color: img.ColorRgb8(value.toInt(), value.toInt(), value.toInt()));
  return frame;
}

double _meanLuminance(img.Image frame) {
  double sum = 0;
  for (final pixel in frame) {
    sum += (pixel.r + pixel.g + pixel.b) / 3.0;
  }
  return sum / (frame.width * frame.height);
}

void main() {
  test('night boost lifts shadows well above the original', () {
    final dark = _solid(52);
    final boosted = applyNightBoost(img.Image.from(dark));
    expect(_meanLuminance(boosted), greaterThan(_meanLuminance(dark) * 1.5));
    expect(_meanLuminance(boosted), lessThanOrEqualTo(255));
  });

  test('night boost keeps highlights from clipping hard', () {
    final bright = _solid(240);
    final boosted = applyNightBoost(img.Image.from(bright));
    // Still recognizable as "bright", not blown to pure white everywhere.
    expect(_meanLuminance(boosted), greaterThanOrEqualTo(240));
    expect(_meanLuminance(boosted), lessThan(256));
  });

  test('alpha channel is untouched', () {
    final frame = img.Image(width: 2, height: 2, numChannels: 4);
    for (final pixel in frame) {
      pixel
        ..r = 10
        ..g = 10
        ..b = 10
        ..a = 128;
    }
    final boosted = applyNightBoost(frame);
    for (final pixel in boosted) {
      expect(pixel.a.toInt(), 128);
    }
  });
}
