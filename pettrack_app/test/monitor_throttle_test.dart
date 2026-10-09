import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/monitor_throttle.dart';

void main() {
  group('frameIntervalMs', () {
    test('a healthy battery streams at the asked-for speed', () {
      expect(
        frameIntervalMs(baseFps: 0.5, batteryLevel: 80, isCharging: false),
        2000,
      );
      expect(
        frameIntervalMs(baseFps: 1.0, batteryLevel: 80, isCharging: false),
        1000,
      );
    });

    test('low battery halves the pace, critical quarters it', () {
      expect(
        frameIntervalMs(baseFps: 0.5, batteryLevel: 15, isCharging: false),
        4000,
      );
      expect(
        frameIntervalMs(baseFps: 0.5, batteryLevel: 5, isCharging: false),
        8000,
      );
    });

    test('charging keeps full pace even at 5%', () {
      expect(
        frameIntervalMs(baseFps: 0.5, batteryLevel: 5, isCharging: true),
        2000,
      );
    });

    test('a nonsense base pace falls back to the default', () {
      expect(
        frameIntervalMs(baseFps: 0, batteryLevel: 80, isCharging: false),
        2000,
      );
    });
  });

  group('isThrottled', () {
    test('only when unplugged and low', () {
      expect(isThrottled(batteryLevel: 20, isCharging: false), isTrue);
      expect(isThrottled(batteryLevel: 21, isCharging: false), isFalse);
      expect(isThrottled(batteryLevel: 5, isCharging: true), isFalse);
    });
  });
}
