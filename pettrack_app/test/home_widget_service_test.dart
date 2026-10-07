import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/services/home_widget_service.dart';

void main() {
  group('shouldPushWidget', () {
    test('the first push is always allowed', () {
      expect(
        shouldPushWidget(lastPush: null, now: DateTime(2026, 10, 7, 10)),
        isTrue,
      );
    });

    test('a push inside the interval is suppressed', () {
      final now = DateTime(2026, 10, 7, 10);
      expect(
        shouldPushWidget(
          lastPush: now.subtract(const Duration(seconds: 29)),
          now: now,
        ),
        isFalse,
      );
    });

    test('a push at the interval boundary goes through', () {
      final now = DateTime(2026, 10, 7, 10);
      expect(
        shouldPushWidget(
          lastPush: now.subtract(kWidgetRefreshInterval),
          now: now,
        ),
        isTrue,
      );
    });

    test('a custom interval is honoured', () {
      final now = DateTime(2026, 10, 7, 10);
      expect(
        shouldPushWidget(
          lastPush: now.subtract(const Duration(seconds: 5)),
          now: now,
          interval: const Duration(seconds: 5),
        ),
        isTrue,
      );
    });
  });

  group('WidgetSnapshot', () {
    test('carries every field the widget paints', () {
      const snap = WidgetSnapshot(
        title: 'Berci',
        status: 'Live',
        batteryLabel: '82%',
        emptyHint: 'Open PetTrack',
      );
      expect(snap.title, 'Berci');
      expect(snap.status, 'Live');
      expect(snap.batteryLabel, '82%');
      expect(snap.emptyHint, 'Open PetTrack');
      expect(snap.png, isNull);
    });
  });
}
