/// CSV export of the activity feed: pure builders, exported for tests.
///
/// The file is meant for spreadsheets — RFC 4180 quoting and CRLF line
/// endings, English column headers, localized cells in the row body.
library;

/// Escape one CSV field (RFC 4180): quotes when it holds a delimiter,
/// quote or newline, doubling any inner quotes.
String csvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// The feed as CSV.
///
/// [rows] hold the already-localized cells in feed order, each shaped
/// `timestamp, iso_time, event_type, zone, title, details`.
String buildFeedCsv(List<List<String>> rows) {
  const header = [
    'timestamp',
    'iso_time',
    'event_type',
    'zone',
    'title',
    'details',
  ];
  final lines = <String>[
    header.map(csvField).join(','),
    for (final row in rows) row.map(csvField).join(','),
  ];
  // CRLF and a trailing line break — what spreadsheets expect (RFC 4180).
  return '${lines.join('\r\n')}\r\n';
}

/// `pettrack-feed-20261009-1412.csv` — sortable, time-stamped.
String feedCsvFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'pettrack-feed-${now.year}${two(now.month)}${two(now.day)}'
      '-${two(now.hour)}${two(now.minute)}.csv';
}
