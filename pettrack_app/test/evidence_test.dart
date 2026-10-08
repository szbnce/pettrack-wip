import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/evidence.dart';

void main() {
  group('nearestClipTo', () {
    final clips = [
      {'filename': 'a.mp4', 'timestamp': 1000},
      {'filename': 'b.mp4', 'timestamp': 2000},
      {'filename': 'c.mp4', 'timestamp': 100000},
      {'filename': 'broken.mp4'}, // no timestamp — never the evidence
    ];

    test('picks the closest clip to the moment', () {
      expect(nearestClipTo(clips, 1100)?['filename'], 'a.mp4');
      expect(nearestClipTo(clips, 1900)?['filename'], 'b.mp4');
    });

    test('a moment between two clips goes to the nearer one', () {
      expect(nearestClipTo(clips, 1400)?['filename'], 'a.mp4');
      expect(nearestClipTo(clips, 1600)?['filename'], 'b.mp4');
      // Outside every reach, not merely the farthest clip.
      expect(
        nearestClipTo(clips, 1500, reachSeconds: 400)?['filename'],
        isNull,
      );
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
