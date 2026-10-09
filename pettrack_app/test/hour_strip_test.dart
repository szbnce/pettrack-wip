import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/hour_strip.dart';

void main() {
  group('hourLabel', () {
    test('pads to two digits', () {
      expect(hourLabel(0), '00');
      expect(hourLabel(9), '09');
      expect(hourLabel(23), '23');
    });
  });

  group('hourBarHeight', () {
    test('empty hours stay on the baseline', () {
      expect(hourBarHeight(0, 10), 2);
      expect(hourBarHeight(5, 0), 2);
    });

    test('the busiest hour fills the strip and the rest scale to it', () {
      expect(hourBarHeight(10, 10), 48);
      expect(hourBarHeight(5, 10), 26);
    });

    test('a taller strip scales', () {
      expect(hourBarHeight(1, 1, maxHeight: 20), 20);
    });
  });
}
