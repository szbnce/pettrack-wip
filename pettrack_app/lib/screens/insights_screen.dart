import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import '../models/insights_data.dart';
import '../theme/colors.dart';
import '../utils/format_helpers.dart';
import '../utils/insights_card.dart';
import '../utils/insights_share.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_box.dart';
import '../services/auth_service.dart';

/// Activity insights: how much the pet moves, where it spends its time,
/// and how much of the day is rest — over a selectable window.
///
/// Chart marks use the validated series steps in [AppColors.chartSeriesOf],
/// one series at a time, with a table twin so every number is readable.
class InsightsScreen extends StatefulWidget {
  final String serverIp;
  final String token;

  const InsightsScreen({
    super.key,
    required this.serverIp,
    required this.token,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const List<int> _ranges = [7, 14, 30];

  int _rangeDays = 14;
  InsightsData? _data;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _asTable = false;

  @override
  void initState() {
    super.initState();
    // After the first frame: demo data needs the localized zone names.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  bool get _isDemo => widget.serverIp.contains('demo_ip');

  Future<void> _fetch({bool haptic = false}) async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    if (_isDemo) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _data = InsightsData.demo(
          rangeDays: _rangeDays,
          zoneNames: [
            l10n.demoZoneKitchen,
            l10n.demoZoneSofa,
            l10n.demoZoneBed,
            l10n.demoZoneGarden,
          ],
        );
        _isLoading = false;
      });
      if (haptic) HapticFeedback.lightImpact();
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/insights?days=$_rangeDays'),
            headers: AuthService.headers,
          )
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _data = InsightsData.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
          _isLoading = false;
        });
        if (haptic) HapticFeedback.lightImpact();
      } else {
        setState(() {
          _loadFailed = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _isLoading = false;
      });
    }
  }

  /// "2 h 15 min" / "45 min" / "20 s" — always in whole units.
  String _duration(double seconds, AppLocalizations l10n) =>
      formatDurationSeconds(l10n, seconds);

  /// "4 – 10 Oct" for the card's subtitle. The card never formats dates
  /// itself, so the range reads the same way as the rest of the app.
  String _datesLabel(List<InsightDay> window) {
    final localizations = MaterialLocalizations.of(context);
    if (window.isEmpty) return '';
    final first = DateTime.parse(window.first.date);
    final last = DateTime.parse(window.last.date);
    final from = localizations.formatMediumDate(first);
    final to = localizations.formatMediumDate(last);
    return first == last ? from : '$from – $to';
  }

  /// The pet's name, as Settings writes it — the card's title names them.
  Future<String> _petName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pet_name') ?? '';
  }

  /// Show the card before it leaves: the post the owner is about to make,
  /// with the image and the text form as two honest choices.
  Future<void> _shareSummary() async {
    final data = _data;
    if (data == null) return;
    final l10n = AppLocalizations.of(context)!;
    final petName = await _petName();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _InsightsShareSheet(
        l10n: l10n,
        data: data,
        rangeDays: _rangeDays,
        petName: petName,
        datesLabel: _datesLabel(data.daysInRange(_rangeDays)),
      ),
    );
  }

  String _dayLabel(BuildContext context, String date) =>
      MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(date));

  String _weekdayShort(BuildContext context, String date) {
    final localizations = MaterialLocalizations.of(context);
    final day = DateTime.parse(date);
    return localizations.narrowWeekdays[day.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insightsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.tooltipShare,
            onPressed: _data == null || _isLoading ? null : _shareSummary,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRangeFilter(l10n, theme),
                  const SizedBox(height: 16),
                  if (_isLoading) ...[
                    const SkeletonBox(height: 88),
                    const SizedBox(height: 16),
                    const SkeletonBox(height: 260),
                  ] else if (_loadFailed) ...[
                    EmptyState(
                      icon: Icons.insights_outlined,
                      title: l10n.insightsLoadError,
                      actionLabel: l10n.retry,
                      onAction: () => _fetch(haptic: true),
                    ),
                  ] else if (_data != null) ...[
                    _buildStatTiles(l10n, theme),
                    const SizedBox(height: 16),
                    _buildActivityCard(l10n, theme),
                    const SizedBox(height: 16),
                    _buildZoneCard(l10n, theme),
                    const SizedBox(height: 16),
                    _buildMeterCard(l10n, theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The one filter row: it scopes every number and chart below it.
  Widget _buildRangeFilter(AppLocalizations l10n, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final range in _ranges)
          ChoiceChip(
            label: Text(l10n.insightsRangeDays(range)),
            selected: _rangeDays == range,
            onSelected: (selected) {
              if (!selected || _rangeDays == range) return;
              setState(() => _rangeDays = range);
              _fetch(haptic: true);
            },
          ),
      ],
    );
  }

  Widget _buildStatTiles(AppLocalizations l10n, ThemeData theme) {
    final data = _data!;
    final window = data.daysInRange(_rangeDays);
    final today = window.last;
    final average = data.averageActiveSeconds(_rangeDays);
    final topZone = data.topZone(_rangeDays);
    final topZoneSeconds = topZone == null
        ? 0.0
        : data
              .zoneTotals(_rangeDays)
              .firstWhere((entry) => entry.key == topZone)
              .value;

    return Row(
      children: [
        Expanded(
          child: _statTile(
            theme,
            title: l10n.insightsActiveToday,
            value: _duration(today.activeSeconds, l10n),
            caption: l10n.insightsClips(today.clips),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            theme,
            title: l10n.insightsAvgPerDay,
            value: _duration(average, l10n),
            caption: l10n.insightsSounds(
              window.fold<int>(0, (sum, d) => sum + d.sounds),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            theme,
            title: l10n.insightsMostActiveZone,
            value: topZone ?? '—',
            caption: topZone == null
                ? l10n.insightsZoneEmpty
                : _duration(topZoneSeconds, l10n),
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    ThemeData theme, {
    required String title,
    required String value,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Active minutes per day — one series, so no legend; the busiest day is
  /// labelled directly and every day is one tap away.
  Widget _buildActivityCard(AppLocalizations l10n, ThemeData theme) {
    final window = _data!.daysInRange(_rangeDays);

    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.insightsActivityChart,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_asTable ? Icons.show_chart : Icons.table_rows),
                tooltip: _asTable
                    ? l10n.tooltipInsightsChart
                    : l10n.tooltipInsightsList,
                onPressed: () => setState(() => _asTable = !_asTable),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_asTable)
            _buildActivityTable(l10n, theme, window)
          else
            _buildActivityChart(l10n, theme, window),
        ],
      ),
    );
  }

  Widget _buildActivityChart(
    AppLocalizations l10n,
    ThemeData theme,
    List<InsightDay> window,
  ) {
    final series = AppColors.chartSeriesOf(context);
    final grid = theme.colorScheme.outline.withValues(alpha: 0.2);
    final axisText = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    );
    final minutes = [for (final day in window) day.activeMinutes.toDouble()];
    final maxValue = minutes.fold<double>(0, (a, b) => math.max(a, b));
    final maxY = math.max(10.0, (maxValue * 1.2).ceilToDouble());
    // Label only the busiest day — a number on every column is noise.
    final maxIndex = minutes.indexOf(maxValue);
    final showLabel = maxValue > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Thin columns: at most 24 px thick, never touching each other.
        final barWidth = (constraints.maxWidth / window.length * 0.55)
            .clamp(4.0, 24.0)
            .toDouble();
        return SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = window[group.x];
                    return BarTooltipItem(
                      '${_dayLabel(context, day.date)}\n'
                      '${_duration(day.activeSeconds, l10n)}',
                      TextStyle(
                        color: theme.colorScheme.onInverseSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: grid, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) =>
                        Text('${value.toInt()}', style: axisText),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    // 30 days is too many weekday letters — thin them out.
                    interval: math.max(1.0, (window.length / 8).ceilToDouble()),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= window.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _weekdayShort(context, window[index].date),
                          style: axisText,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < window.length; i++)
                  BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: showLabel && i == maxIndex
                        ? [0]
                        : const [],
                    barRods: [
                      BarChartRodData(
                        toY: math.max(minutes[i], 0.0),
                        width: barWidth,
                        color: series,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The table twin of the column chart: exact values, text only.
  Widget _buildActivityTable(
    AppLocalizations l10n,
    ThemeData theme,
    List<InsightDay> window,
  ) {
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );
    final valueStyle = theme.textTheme.bodyMedium;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.insightsTableDay, style: labelStyle)),
            Text(l10n.insightsWordActive, style: labelStyle),
          ],
        ),
        const SizedBox(height: 4),
        for (final day in window.reversed) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(_dayLabel(context, day.date), style: valueStyle),
                ),
                Text(_duration(day.activeSeconds, l10n), style: valueStyle),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Seconds per zone, biggest first — magnitude, so one hue for all bars,
  /// with the value spelled out at each tip.
  Widget _buildZoneCard(AppLocalizations l10n, ThemeData theme) {
    final zones = _data!.zoneTotals(_rangeDays);
    final series = AppColors.chartSeriesOf(context);
    final maxValue = zones.isEmpty ? 0.0 : zones.first.value;

    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsZoneChart,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (zones.isEmpty)
            Text(
              l10n.insightsZoneEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final zone in zones)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        zone.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: maxValue <= 0
                              ? 0
                              : math.max(0.02, zone.value / maxValue),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: series,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: Text(
                        _duration(zone.value, l10n),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /// A single ratio against a limit: the average day's motion against the
  /// day itself. A pet's day is mostly rest — that sliver is the insight.
  Widget _buildMeterCard(AppLocalizations l10n, ThemeData theme) {
    final series = AppColors.chartSeriesOf(context);
    final active = _data!.averageActiveSeconds(_rangeDays);
    const day = 24 * 60 * 60.0;
    final share = (active / day).clamp(0.0, 1.0).toDouble();

    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsActiveVsRest,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Never an invisible fill: at least 4 px of track is filled
              // whenever there is any activity at all.
              final width = share <= 0
                  ? 0.0
                  : math.max(4.0, constraints.maxWidth * share);
              return Stack(
                children: [
                  Container(
                    height: 10,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: series.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 10,
                    width: width,
                    decoration: BoxDecoration(
                      color: series,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.insightsWordActive} · ${_duration(active, l10n)}',
                style: theme.textTheme.labelMedium,
              ),
              Text(
                '${l10n.insightsWordRest} · ${_duration(day - active, l10n)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }
}

/// The card's send-off: see the post first, then pick the form it leaves in.
class _InsightsShareSheet extends StatefulWidget {
  final AppLocalizations l10n;
  final InsightsData data;
  final int rangeDays;
  final String petName;
  final String datesLabel;

  const _InsightsShareSheet({
    required this.l10n,
    required this.data,
    required this.rangeDays,
    required this.petName,
    required this.datesLabel,
  });

  @override
  State<_InsightsShareSheet> createState() => _InsightsShareSheetState();
}

class _InsightsShareSheetState extends State<_InsightsShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _asImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await shareInsightsCardPng(_cardKey);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('insights card share failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.l10n.shareFailed)));
    }
  }

  Future<void> _asText() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: buildInsightsShareText(
            widget.l10n,
            widget.data,
            widget.rangeDays,
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('insights text share failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.l10n.shareFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.insightsCardShareTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // The card paints at its own fixed size; the box only scales the
            // preview. The PNG is taken from the unscaled card behind it.
            SizedBox(
              height: 300,
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: InsightsCard(
                    l10n: l10n,
                    data: widget.data,
                    rangeDays: widget.rangeDays,
                    petName: widget.petName,
                    datesLabel: widget.datesLabel,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _asImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(l10n.insightsCardShareImage),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy ? null : _asText,
              icon: const Icon(Icons.notes_outlined),
              label: Text(l10n.insightsCardShareText),
            ),
          ],
        ),
      ),
    );
  }
}
