import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/event_feedback.dart';

void main() {
  group('isFeedbackKind', () {
    test('only the two teaching kinds', () {
      expect(isFeedbackKind(feedbackKindNotMyPet), isTrue);
      expect(isFeedbackKind(feedbackKindIsMyPet), isTrue);
      expect(isFeedbackKind('banana'), isFalse);
      expect(isFeedbackKind(null), isFalse);
    });
  });

  group('feedbackPayload', () {
    test('carries the moment and the label', () {
      final body = feedbackPayload(
        timestampSeconds: 1700000123.5,
        kind: feedbackKindNotMyPet,
      );
      expect(body['timestamp'], 1700000123.5);
      expect(body['kind'], 'not_my_pet');
      expect(body.containsKey('event_type'), isFalse);
      expect(body.containsKey('zone_name'), isFalse);
      expect(body.containsKey('filename'), isFalse);
    });

    test('keeps the event context when there is any', () {
      final body = feedbackPayload(
        timestampSeconds: 42,
        kind: feedbackKindIsMyPet,
        eventType: 'zone_enter',
        zoneName: 'Kitchen',
        filename: 'clip.mp4',
      );
      expect(body['event_type'], 'zone_enter');
      expect(body['zone_name'], 'Kitchen');
      expect(body['filename'], 'clip.mp4');
    });

    test('blank context is left out, not sent empty', () {
      final body = feedbackPayload(
        timestampSeconds: 1,
        kind: feedbackKindNotMyPet,
        eventType: '',
        zoneName: '',
        filename: '',
      );
      expect(body.containsKey('event_type'), isFalse);
      expect(body.containsKey('zone_name'), isFalse);
      expect(body.containsKey('filename'), isFalse);
    });
  });
}
