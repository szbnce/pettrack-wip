/// Hourly density strip geometry — pure helpers, exported for tests.
library;

/// "00" … "23" — the tick under a bar, and the hour in a tooltip.
String hourLabel(int hour) => hour.toString().padLeft(2, '0');

/// Bar height for [total] against the busiest hour [maxTotal].
///
/// Empty hours sit at 2px so the baseline still reads as a line of day;
/// the busiest hour fills [maxHeight].
double hourBarHeight(int total, int maxTotal, {double maxHeight = 48}) {
  if (total <= 0 || maxTotal <= 0) return 2;
  return 4 + (total / maxTotal) * (maxHeight - 4);
}
