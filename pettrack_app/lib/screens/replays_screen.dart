import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/video_player_widget.dart';
import '../services/auth_service.dart';

class ReplaysScreen extends StatefulWidget {
  final String serverIp;
  final String token;

  const ReplaysScreen({super.key, required this.serverIp, required this.token});

  @override
  State<ReplaysScreen> createState() => _ReplaysScreenState();
}

class _ReplaysScreenState extends State<ReplaysScreen> {
  List<dynamic> _replays = [];
  bool _isLoading = true;
  // Error state is kept structured so the localized message can be
  // built safely in build() (no BuildContext use after async gaps).
  int _errorStatus = 0;
  String _errorDetail = '';

  /// Per-day buckets from /api/timeline, keyed by "YYYY-MM-DD".
  Map<String, dynamic> _timelineByDay = {};

  /// Day picked in the strip (local midnight), or null for "all days".
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchReplays();
  }

  bool get _isDemo => widget.serverIp.contains('demo_ip');

  Future<void> _fetchReplays({bool haptic = false}) async {
    setState(() {
      _isLoading = true;
      _errorStatus = 0;
      _errorDetail = '';
    });

    if (_isDemo) {
      _loadDemoData();
      if (haptic) HapticFeedback.lightImpact();
      return;
    }

    try {
      // The clip list and the day-strip dots load together so a pull-to
      // refresh can never show one without the other.
      final responses = await Future.wait([
        http
            .get(
              Uri.parse('${widget.serverIp}/api/replays'),
              headers: AuthService.headers,
            )
            .timeout(const Duration(seconds: 5)),
        http
            .get(
              Uri.parse('${widget.serverIp}/api/timeline?days=14'),
              headers: AuthService.headers,
            )
            .timeout(const Duration(seconds: 5)),
      ]);
      if (!mounted) return;
      final response = responses[0];
      final timeline = responses[1];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // A failed timeline is not a failed screen — the strip just
        // renders without dots.
        final days = timeline.statusCode == 200
            ? (jsonDecode(timeline.body)['days'] as List? ?? [])
            : const [];
        setState(() {
          _replays = data['replays'] ?? [];
          _timelineByDay = {
            for (final day in days) (day['date'] as String): day,
          };
          _isLoading = false;
        });
        if (haptic) HapticFeedback.lightImpact();
      } else {
        setState(() {
          _errorStatus = response.statusCode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorDetail = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Demo mode: synthetic clips and event dots, so the timeline and the
  /// grid can be explored without a camera or a server.
  void _loadDemoData() {
    final now = DateTime.now();
    final clips = List.generate(6, (i) {
      final ts = now.subtract(Duration(hours: 5 + i * 17));
      return <String, dynamic>{
        'filename': 'demo_replay_$i.mp4',
        'timestamp': ts.millisecondsSinceEpoch ~/ 1000,
        'size': (2 + i) * 1024 * 1024,
        'url': '',
      };
    });

    const types = ['zone_enter', 'sound_detected', 'zone_exit'];
    final byDay = <String, dynamic>{};
    for (final clip in clips) {
      final day = DateTime.fromMillisecondsSinceEpoch(
        (clip['timestamp'] as int) * 1000,
      );
      final key = _dayKey(day);
      final bucket = byDay.putIfAbsent(
        key,
        () => <String, dynamic>{
          'date': key,
          'events': <String, dynamic>{},
          'total': 0,
          'clips': 0,
        },
      );
      bucket['clips'] = (bucket['clips'] as int) + 1;
      final events = bucket['events'] as Map<String, dynamic>;
      final type = types[events.length % types.length];
      events[type] = (events[type] as int? ?? 0) + 2;
      bucket['total'] = (bucket['total'] as int) + 2;
    }

    setState(() {
      _replays = clips;
      _timelineByDay = byDay;
      _isLoading = false;
    });
  }

  /// Playback needs real video; demo mode just says so.
  void _demoPlayback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.demoNoPlayback)),
    );
  }

  /// The strip always covers the last two weeks, quiet days included, so
  /// gaps in the pet's activity are visible too.
  List<DateTime> _stripDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));
  }

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// YYYY-MM-DD of the selected day, or null meaning "no filter / today".
  String? get _dayFilter =>
      _selectedDay == null ? null : _dayKey(_selectedDay!);

  List<dynamic> get _visibleReplays {
    final day = _selectedDay;
    if (day == null) return _replays;
    final start = day.millisecondsSinceEpoch ~/ 1000;
    final end = start + 24 * 60 * 60;
    return _replays.where((r) {
      final ts = (r['timestamp'] as num).toInt();
      return ts >= start && ts < end;
    }).toList();
  }

  /// Same colours as the dashboard activity feed, so a dot always means
  /// the same kind of thing in both places.
  Color _eventDotColor(String type) {
    switch (type) {
      case 'sound_detected':
        return AppColors.tertiary;
      case 'zone_enter':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }

  void _showBuildingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(Map<String, dynamic> replay) {
    if (_isDemo) {
      _demoPlayback();
      return;
    }
    // The server returns a signed, file-scoped URL (short-lived token).
    // Fallback for older servers: put the session token into the URL.
    final signedPath =
        replay['url'] as String? ??
        '/api/replays/${replay['filename']}?token=${widget.token}';
    _showVideoDialog(
      url: '${widget.serverIp}$signedPath',
      heroTag: 'replay-${replay['filename']}',
    );
  }

  /// Build a day's timelapse on the server (cached there) and play it.
  /// [date] is "YYYY-MM-DD"; null means today.
  Future<void> _openTimelapse({String? date}) async {
    if (_isDemo) {
      _demoPlayback();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    // ffmpeg can take a while on a first build — show that we are working.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    _showBuildingDialog(l10n.timelapseBuilding);

    try {
      final query = date == null ? '' : '?date=$date';
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/timelapse$query'),
            headers: AuthService.headers,
          )
          .timeout(const Duration(seconds: 60));

      navigator.pop(); // close the loading dialog
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final signedPath = data['url'] as String? ?? '';
        _showVideoDialog(
          url: '${widget.serverIp}$signedPath',
          heroTag: 'timelapse-${data['filename']}',
        );
      } else if (response.statusCode == 404) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.timelapseEmpty)));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.timelapseError(response.statusCode))),
        );
      }
    } catch (e) {
      navigator.pop(); // close the loading dialog
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.replaysNetworkError(e.toString()))),
      );
    }
  }

  /// Build a day's recap (its motion moments stitched together) and play it.
  /// [date] is "YYYY-MM-DD"; null means today.
  Future<void> _openRecap({String? date}) async {
    if (_isDemo) {
      _demoPlayback();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    _showBuildingDialog(l10n.recapBuilding);

    try {
      final query = date == null ? '' : '?date=$date';
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/highlight$query'),
            headers: AuthService.headers,
          )
          .timeout(const Duration(seconds: 60));

      navigator.pop(); // close the loading dialog
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final signedPath = data['url'] as String? ?? '';
        _showVideoDialog(
          url: '${widget.serverIp}$signedPath',
          heroTag: 'recap-${data['filename']}',
        );
      } else if (response.statusCode == 404) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.recapEmpty)));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.recapError(response.statusCode))),
        );
      }
    } catch (e) {
      navigator.pop(); // close the loading dialog
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.replaysNetworkError(e.toString()))),
      );
    }
  }

  /// One-tap share from the player: hand the actual clip file to the system
  /// share sheet. The URL is signed and short-lived, so the bytes are fetched
  /// right away.
  Future<void> _shareVideo(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final dir = await getTemporaryDirectory();
      final segments = Uri.parse(url).pathSegments;
      final name = segments.isNotEmpty ? segments.last : 'pettrack_clip.mp4';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: l10n.shareInviteText),
      );
    } catch (e) {
      debugPrint('clip share failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  void _showVideoDialog({required String url, String? heroTag}) {
    final l10n = AppLocalizations.of(context)!;
    Widget player = Container(
      color: Colors.black,
      child: VideoPlayerWidget(videoUrl: url),
    );
    if (heroTag != null) player = Hero(tag: heroTag, child: player);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: player),
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.close),
                    ),
                    TextButton.icon(
                      onPressed: () => _shareVideo(url),
                      icon: const Icon(Icons.share),
                      label: Text(l10n.tooltipShare),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: Text(l10n.openDownload),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two-week strip of days with event dots — tap a day to filter the grid.
  Widget _buildDayStrip(AppLocalizations l10n, ThemeData theme) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l10n.replayAllDays),
              selected: _selectedDay == null,
              onSelected: (_) => setState(() => _selectedDay = null),
            ),
          ),
          for (final day in _stripDays()) _buildDayCell(day, theme),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, ThemeData theme) {
    final bucket = _timelineByDay[_dayKey(day)] as Map<String, dynamic>?;
    final events = (bucket?['events'] as Map?) ?? const {};
    final clips = (bucket?['clips'] as num?)?.toInt() ?? 0;
    final isSelected =
        _selectedDay != null &&
        _selectedDay!.year == day.year &&
        _selectedDay!.month == day.month &&
        _selectedDay!.day == day.day;
    final now = DateTime.now();
    final isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;
    // MaterialLocalizations carries the locale's own narrow weekday labels,
    // Sunday first — weekday is 1 (Mon) … 7 (Sun).
    final weekday = MaterialLocalizations.of(
      context,
    ).narrowWeekdays[day.weekday % 7];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() {
          _selectedDay = isSelected ? null : day;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.25)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.2,
                  ),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? AppColors.primary : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final type in events.keys.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _eventDotColor(type as String),
                      ),
                    ),
                ],
              ),
              if (clips > 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.movie, size: 10, color: Colors.white54),
                    const SizedBox(width: 2),
                    Text(
                      '$clips',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Per-day builds for whichever day is selected in the strip.
  Widget _buildDayActions(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openTimelapse(date: _dayFilter),
              icon: const Icon(Icons.timelapse, size: 18),
              label: Text(l10n.tooltipTimelapse),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openRecap(date: _dayFilter),
              icon: const Icon(Icons.movie_filter, size: 18),
              label: Text(l10n.tooltipRecap),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplayGrid(
    List<dynamic> replays,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDesktop,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 16 / 9,
      ),
      itemCount: replays.length,
      itemBuilder: (context, index) {
        final replay = replays[index];
        final date = DateTime.fromMillisecondsSinceEpoch(
          replay['timestamp'] * 1000,
        );
        final dateString =
            "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        final sizeMb = (replay['size'] / (1024 * 1024)).toStringAsFixed(1);

        return InkWell(
          onTap: () => _playVideo(replay),
          borderRadius: BorderRadius.circular(12),
          child: Hero(
            tag: 'replay-${replay['filename']}',
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateString,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.replaySizeMb(sizeMb),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    Widget content;
    if (_isLoading) {
      content = SkeletonGrid(crossAxisCount: isDesktop ? 3 : 2);
    } else if (_errorStatus != 0 || _errorDetail.isNotEmpty) {
      final errorText = _errorStatus != 0
          ? l10n.replaysLoadError(_errorStatus)
          : l10n.replaysNetworkError(_errorDetail);
      content = EmptyState(
        icon: Icons.error_outline,
        title: errorText,
        actionLabel: l10n.retry,
        onAction: () => _fetchReplays(haptic: true),
        iconColor: Colors.redAccent,
        textColor: Colors.white70,
      );
    } else if (_replays.isEmpty && _timelineByDay.isEmpty) {
      content = EmptyState(
        icon: Icons.videocam_off_outlined,
        title: l10n.noReplays,
        textColor: Colors.white54,
        iconColor: Colors.white24,
        actionLabel: l10n.retry,
        onAction: () => _fetchReplays(haptic: true),
      );
    } else {
      final visible = _visibleReplays;
      final grid = visible.isEmpty
          ? EmptyState(
              icon: Icons.event_busy_outlined,
              title: l10n.noReplaysForDay,
              textColor: Colors.white54,
              iconColor: Colors.white24,
              actionLabel: l10n.replayAllDays,
              onAction: () => setState(() => _selectedDay = null),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchReplays(haptic: true),
              child: _buildReplayGrid(visible, l10n, theme, isDesktop),
            );
      content = Column(
        children: [
          _buildDayStrip(l10n, theme),
          if (_selectedDay != null) _buildDayActions(l10n),
          Expanded(child: grid),
        ],
      );
    }

    return isDesktop
        ? Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.replaysTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.timelapse),
                          tooltip: l10n.tooltipTimelapse,
                          onPressed: () => _openTimelapse(date: _dayFilter),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: l10n.tooltipRefresh,
                          onPressed: () => _fetchReplays(haptic: true),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: content),
              ],
            ),
          )
        : Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () => _openTimelapse(date: _dayFilter),
                  tooltip: l10n.tooltipTimelapse,
                  mini: true,
                  child: const Icon(Icons.timelapse),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  onPressed: () => _fetchReplays(haptic: true),
                  tooltip: l10n.tooltipRefresh,
                  mini: true,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: content,
          );
  }
}
