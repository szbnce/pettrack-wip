import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/sound_detect.dart';

void main() {
  group('isSoundLevelEvent', () {
    test('a quiet room is not an event', () {
      expect(isSoundLevelEvent(-50), isFalse);
    });

    test('a loud bark is an event', () {
      expect(isSoundLevelEvent(-15), isTrue);
    });

    test('the threshold is inclusive', () {
      expect(isSoundLevelEvent(kSoundThresholdDb), isTrue);
      expect(isSoundLevelEvent(kSoundThresholdDb - 0.1), isFalse);
    });

    test('a custom threshold is honoured', () {
      expect(isSoundLevelEvent(-10, threshold: -5), isFalse);
      expect(isSoundLevelEvent(-10, threshold: -20), isTrue);
    });
  });
}
