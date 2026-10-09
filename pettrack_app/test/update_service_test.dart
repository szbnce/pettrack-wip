import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/services/update_service.dart';

void main() {
  group('updateIsNewer', () {
    test('a higher version is an update', () {
      expect(updateIsNewer('2.1.0', '2.0.0'), isTrue);
      expect(updateIsNewer('2.0.1', '2.0.0'), isTrue);
      expect(updateIsNewer('3.0.0', '2.9.9'), isTrue);
    });

    test('the same or an older version is not an update', () {
      expect(updateIsNewer('2.0.0', '2.0.0'), isFalse);
      expect(updateIsNewer('1.9.9', '2.0.0'), isFalse);
      expect(updateIsNewer('2.0.0', '2.0.1'), isFalse);
    });

    test('short versions are zero-padded', () {
      expect(updateIsNewer('2.0.1', '2.0'), isTrue);
      expect(updateIsNewer('2', '2.0.0'), isFalse);
    });
  });

  group('AppUpdate.fromPayload', () {
    test('a newer staged version becomes an update with its size', () {
      final update = AppUpdate.fromPayload({
        'version': '2.1.0',
        'apk_bytes': 123,
      }, currentVersion: '2.0.0');
      expect(update, isNotNull);
      expect(update!.version, '2.1.0');
      expect(update.sizeBytes, 123);
    });

    test('nothing staged means no update', () {
      expect(AppUpdate.fromPayload({'version': null}), isNull);
      expect(AppUpdate.fromPayload({'version': ''}), isNull);
      expect(AppUpdate.fromPayload({}), isNull);
    });

    test('the version we already run is not an update', () {
      expect(
        AppUpdate.fromPayload({'version': '2.0.0'}, currentVersion: '2.0.0'),
        isNull,
      );
      expect(
        AppUpdate.fromPayload({'version': '1.9.0'}, currentVersion: '2.0.0'),
        isNull,
      );
    });

    test('a missing size is tolerated', () {
      final update = AppUpdate.fromPayload({
        'version': '2.1.0',
      }, currentVersion: '2.0.0');
      expect(update!.sizeBytes, 0);
    });
  });
}
