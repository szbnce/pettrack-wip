/// The shareable card behind Insights' image share: the kind of thing a pet
/// owner posts — a name, the headline number, the week's shape, and where
/// the time went.
///
/// The card wears its own colours on purpose. A post is a post on every
/// phone, so it does not follow the viewer's theme.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/insights_data.dart';
import '../theme/colors.dart';
import 'format_helpers.dart';

/// The card's title the way a pet owner would write the post: the pet's
/// name, and the product it came from. A nameless pet gets the generic line.
String insightsCardTitle(AppLocalizations l10n, String petName) {
  final name = petName.trim();
  return name.isEmpty ? l10n.insightsCardGeneric : l10n.insightsCardNamed(name);
}

/// Paints the card at a fixed size so the exported PNG is predictable
/// whatever the phone's text scale is.
class InsightsCard extends StatelessWidget {
  final AppLocalizations l10n;
  final InsightsData data;
  final int rangeDays;
  final String petName;

  /// Already-localised "4 – 10 Oct" (or whatever the range is) — the card
  /// composes it with the range length and never formats dates itself.
  final String datesLabel;

  const InsightsCard({
    super.key,
    required this.l10n,
    required this.data,
    required this.rangeDays,
    required this.petName,
    required this.datesLabel,
  });

  /// Logical size of the exported card. Rendered at 2× it is 1200 × 1440 —
  /// a comfortable portrait post.
  static const double cardWidth = 600;
  static const double cardHeight = 720;

  static const _ink = AppColors.onBackground;
  static const _muted = AppColors.onSurfaceVariant;
  static const _accent = AppColors.primary;
  static const _bar = AppColors.chartSeries;
  static const _rule = Color(0xFFD8DEE8);

  @override
  Widget build(BuildContext context) {
    final window = data.daysInRange(rangeDays);
    final totalActive = window.fold<double>(0, (s, d) => s + d.activeSeconds);
    final avg = data.averageActiveSeconds(rangeDays);
    final clips = window.fold<int>(0, (s, d) => s + d.clips);
    final sounds = window.fold<int>(0, (s, d) => s + d.sounds);
    final topZone = data.topZone(rangeDays);

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        // The same soft card radius the app uses, so the post still reads
        // as PetTrack at thumbnail size.
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insightsCardTitle(l10n, petName),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 40,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.insightsRangeDays(rangeDays)} · $datesLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: _rule),
          const SizedBox(height: 20),
          Text(
            formatDurationSeconds(l10n, totalActive),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 64,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: _accent,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.insightsCardMoving,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.insightsAvgPerDay}: '
            '${formatDurationSeconds(l10n, avg)} · '
            '${l10n.insightsClips(clips)} · '
            '${l10n.insightsSounds(sounds)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: _rule),
          const SizedBox(height: 16),
          Text(
            l10n.insightsActivityChart,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 10),
          // The week's shape takes whatever height the copy above leaves
          // it — a long name must not push the card out of its frame.
          Expanded(
            child: _ActivityBars(days: window, l10n: l10n),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: _rule),
          const SizedBox(height: 16),
          if (topZone != null) ...[
            Text(
              l10n.insightsCardTopZone(topZone),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _bar,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.insightsCardFooter,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One thin bar per day. A single series needs no legend — the caption
/// above names it — and the busiest day is the only one that gets a value,
/// so the eye lands on the shape of the week instead of a row of numbers.
///
/// Sizes itself from the height it is given, so the card never overflows
/// when the copy above happens to run to a second line.
class _ActivityBars extends StatelessWidget {
  final List<InsightDay> days;
  final AppLocalizations l10n;

  const _ActivityBars({required this.days, required this.l10n});

  static const double _weekdayHeight = 18;
  static const double _labelHeight = 22;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final weekday = MaterialLocalizations.of(context).narrowWeekdays;
    final peak = days.fold<double>(
      0,
      (m, d) => d.activeSeconds > m ? d.activeSeconds : m,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final barArea = math.max(
          0.0,
          constraints.maxHeight - _weekdayHeight - _labelHeight - _gap,
        );
        return Column(
          children: [
            SizedBox(
              height: _labelHeight + barArea,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: _BarColumn(
                        day: days[i],
                        peak: peak,
                        barArea: barArea,
                        l10n: l10n,
                        // Only the busiest day speaks — a number on every
                        // bar is a row of noise.
                        showValue: peak > 0 && days[i].activeSeconds >= peak,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: _gap),
            SizedBox(
              height: _weekdayHeight,
              child: Row(
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        // weekday is 1 (Mon) … 7 (Sun); the list starts Sunday.
                        weekday[DateTime.parse(days[i].date).weekday % 7],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarColumn extends StatelessWidget {
  final InsightDay day;
  final double peak;
  final double barArea;
  final AppLocalizations l10n;
  final bool showValue;

  const _BarColumn({
    required this.day,
    required this.peak,
    required this.barArea,
    required this.l10n,
    required this.showValue,
  });

  @override
  Widget build(BuildContext context) {
    // A quiet day still gets a 4px nub — a zero-height bar looks like a
    // rendering bug rather than "nothing happened".
    final fraction = peak <= 0 ? 0.0 : day.activeSeconds / peak;
    final barHeight = math.min(
      barArea,
      4.0 + fraction * math.max(0.0, barArea - 4.0),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: _ActivityBars._labelHeight,
          child: showValue
              ? Text(
                  formatDurationSeconds(l10n, day.activeSeconds),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                )
              : null,
        ),
        // 4px rounded data-ends, anchored to the baseline.
        Container(
          width: double.infinity,
          height: barHeight,
          decoration: const BoxDecoration(
            color: InsightsCard._bar,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      ],
    );
  }
}

/// Rasterise the card sitting behind [boundaryKey] into a PNG. The key must
/// point at a [RepaintBoundary] that has already been painted once.
Future<Uint8List> renderInsightsCardPng(
  GlobalKey boundaryKey, {
  double pixelRatio = 2.0,
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw StateError('Insights card is not laid out yet');
  }
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) throw StateError('Could not encode the card as PNG');
  return bytes.buffer.asUint8List();
}

/// Hand the card to the share sheet. Returns false when it could not be
/// written out — the caller says so in its own words.
Future<bool> shareInsightsCardPng(GlobalKey boundaryKey) async {
  final bytes = await renderInsightsCardPng(boundaryKey);
  final tempDir = await getTemporaryDirectory();
  final file = File(
    '${tempDir.path}/pettrack_insights_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  return true;
}
