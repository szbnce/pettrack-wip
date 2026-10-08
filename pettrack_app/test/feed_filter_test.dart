import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/feed_filter.dart';

void main() {
  group('feedCategoryOf', () {
    test('zone movement is one category', () {
      expect(feedCategoryOf('zone_enter'), feedCategoryZone);
      expect(feedCategoryOf('zone_exit'), feedCategoryZone);
      expect(feedCategoryOf('zone_left'), feedCategoryZone);
    });

    test('sounds and system news split off', () {
      expect(feedCategoryOf('sound_detected'), feedCategorySound);
      expect(feedCategoryOf('camera_offline'), feedCategorySystem);
      expect(feedCategoryOf('disk_low'), feedCategorySystem);
      expect(feedCategoryOf('battery_low'), feedCategorySystem);
    });
  });

  group('matchesFeedFilters', () {
    const texts = ['Milo entered Kitchen', 'Motion detected'];

    test('an empty filter keeps everything', () {
      for (final type in ['zone_enter', 'sound_detected', 'disk_low']) {
        expect(
          matchesFeedFilters(
            eventType: type,
            texts: texts,
            query: '   ',
            category: feedCategoryAll,
          ),
          isTrue,
        );
      }
    });

    test('the query matches any display text, case-insensitively', () {
      expect(
        matchesFeedFilters(
          eventType: 'zone_enter',
          texts: texts,
          query: 'KITCHEN',
          category: feedCategoryAll,
        ),
        isTrue,
      );
      expect(
        matchesFeedFilters(
          eventType: 'zone_enter',
          texts: texts,
          query: 'motion',
          category: feedCategoryAll,
        ),
        isTrue,
      );
      expect(
        matchesFeedFilters(
          eventType: 'zone_enter',
          texts: texts,
          query: 'sofa',
          category: feedCategoryAll,
        ),
        isFalse,
      );
    });

    test('category and query must both pass', () {
      expect(
        matchesFeedFilters(
          eventType: 'zone_enter',
          texts: texts,
          query: 'kitchen',
          category: feedCategorySound,
        ),
        isFalse,
      );
      expect(
        matchesFeedFilters(
          eventType: 'sound_detected',
          texts: ['Sound detected'],
          query: 'sound',
          category: feedCategorySound,
        ),
        isTrue,
      );
    });
  });
}
