import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/app_info.dart';

void main() {
  group('compareVersions', () {
    test('equal versions compare 0', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
    });

    test('orders by major, minor, patch', () {
      expect(compareVersions('1.0.0', '2.0.0'), lessThan(0));
      expect(compareVersions('2.0.0', '1.0.0'), greaterThan(0));
      expect(compareVersions('1.2.0', '1.10.0'), lessThan(0));
      expect(compareVersions('1.0.3', '1.0.2'), greaterThan(0));
    });

    test('missing components count as zero', () {
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1', '1.0.1'), lessThan(0));
    });

    test('non-numeric components count as zero', () {
      expect(compareVersions('1.x.0', '1.0.0'), 0);
      expect(compareVersions('', '0.0.0'), 0);
    });
  });
}
