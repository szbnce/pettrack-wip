import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/evidence.dart';

void main() {
  group('nearestClipTo', () {
    final clips = [
      {'filename': 'a.mp4', 'timestamp': 1000},
      {'filename': 'b.mp4', 'timestamp': 1180},
      {'filename': 'c.mp4', 'timestamp': 100000},
      {'filename': 'broken.mp4'}, // no timestamp — never the evidence
    ];

    test('picks the closest clip to the moment', () {
      expect(nearestClipTo(clips, 1020)?['filename'], 'a.mp4');
      expect(nearestClipTo(clips, 1160)?['filename'], 'b.mp4');
    });

    test('a moment between two clips goes to the nearer one', () {
      expect(nearestClipTo(clips, 1060)?['filename'], 'a.mp4');
      expect(nearestClipTo(clips, 1120)?['filename'], 'b.mp4');
      // Outside every reach, not merely the farthest clip.
      expect(nearestClipTo(clips, 1060, reachSeconds: 40)?['filename'], isNull);
    });

    test('nothing in reach is null, not the farthest clip', () {
      expect(nearestClipTo(clips, 50000), isNull);
      expect(nearestClipTo([], 1500), isNull);
    });

    test('the reach window is inclusive at its edge', () {
      // One clip only: the edge is about reach, not about being nearer.
      const single = [
        {'filename': 'a.mp4', 'timestamp': 1000},
      ];
      expect(
        nearestClipTo(single, 1000 + defaultReachSeconds)?['filename'],
        'a.mp4',
      );
      expect(
        nearestClipTo(single, 1000 + defaultReachSeconds + 1)?['filename'],
        isNull,
      );
    });

    test('a clip twenty minutes away is not evidence', () {
      // Clips last half a minute — one from twenty minutes ago is history,
      // not proof of what happened at this moment.
      const lonely = [
        {'filename': 'old.mp4', 'timestamp': 1000},
      ];
      expect(nearestClipTo(lonely, 1000 + 20 * 60), isNull);
    });
  });

  group('seekOffsetIn', () {
    test('lands on the second the event happened', () {
      final clip = {'filename': 'a.mp4', 'timestamp': 1000};
      expect(seekOffsetIn(clip, 1015), const Duration(seconds: 15));
    });

    test('a moment before the first frame starts at zero', () {
      final clip = {'filename': 'a.mp4', 'timestamp': 1000};
      expect(seekOffsetIn(clip, 990), Duration.zero);
    });

    test('a clip with no timestamp starts at zero', () {
      expect(seekOffsetIn({'filename': 'x.mp4'}, 1500), Duration.zero);
    });
  });

  group('evidence payloads', () {
    test('round-trip the event moment', () {
      expect(parseEvidencePayload(evidencePayload(1728000000)), 1728000000);
    });

    test('foreign payloads parse to null', () {
      expect(parseEvidencePayload('something-else'), isNull);
      expect(parseEvidencePayload('evidence:not-a-number'), isNull);
    });
  });
}
