/// Feed search/filter: pure matching rules for the activity feed.
///
/// Categories are coarse on purpose — zone movement, sounds and system
/// health — because the question a filter answers is "what kind of thing
/// happened?", not "which exact event type?".
const String feedCategoryAll = 'all';
const String feedCategoryZone = 'zone';
const String feedCategorySound = 'sound';
const String feedCategorySystem = 'system';

/// The category an event belongs to; unknown types are system news.
String feedCategoryOf(String? eventType) {
  switch (eventType) {
    case 'zone_enter':
    case 'zone_exit':
    case 'zone_left':
      return feedCategoryZone;
    case 'sound_detected':
      return feedCategorySound;
    default:
      return feedCategorySystem;
  }
}

/// Does one event survive the feed filter?
///
/// The [query] is matched against the event's display [texts] (titles,
/// subtitles, zone names) case-insensitively; a blank query matches all.
/// [category] is one of the feedCategory* values.
bool matchesFeedFilters({
  required String? eventType,
  required List<String> texts,
  required String query,
  required String category,
}) {
  if (category != feedCategoryAll && feedCategoryOf(eventType) != category) {
    return false;
  }
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return texts.any((text) => text.toLowerCase().contains(needle));
}
