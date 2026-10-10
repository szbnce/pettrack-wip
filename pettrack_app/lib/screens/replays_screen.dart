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
import '../utils/evidence.dart';
import '../utils/hour_strip.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/video_player_widget.dart';
import '../services/auth_service.dart';

class ReplaysScreen extends StatefulWidget {
  final String serverIp;
  final String token;

  /// Event → evidence: preselect the day an event happened on.
  final DateTime? initialDay;

  /// The event's unix seconds — with this set, the screen jumps to the
  /// nearest clip to the moment once the grid has loaded.
  final int? initialTimestamp;

  const ReplaysScreen({
    super.key,
    required this.serverIp,
    required this.token,
    this.initialDay,
    this.initialTimestamp,
  });

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

  /// Hourly density of the selected day (24 buckets from /api/timeline/day).
  List<dynamic> _dayHours = [];

  /// Hour picked in the density strip, or null for the whole day.
  int? _selectedHour;

  /// The moment jump happens once per screen, not on every refresh.
  bool _jumpedToMoment = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
    _fetchReplays();
    if (_selectedDay != null) _fetchDayHours(_selectedDay!);
  }

  /// Day-strip selection: the hour strip comes with it, and the hour
  /// filter of the previous day never survives the switch.
  void _selectDay(DateTime? day) {
    setState(() {
      _selectedDay = day;
      _selectedHour = null;
    });
    if (day == null) {
      setState(() => _dayHours = []);
    } else {
      _fetchDayHours(day);
    }
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
        _jumpToMoment();
        // The clip list just changed — the day's strip may have too.
        final selected = _selectedDay;
        if (selected != null) _fetchDayHours(selected);
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
    // The day strip's hours come from these clips too.
    final selected = _selectedDay;
    if (selected != null) _fetchDayHours(selected);
  }

  /// Playback needs real video; demo mode just says so.
  void _demoPlayback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.demoNoPlayback)),
    );
  }

  /// Event → evidence: when a moment was handed in (feed row, alert tap),
  /// play the clip nearest to it. Half an hour is the reach — further away
  /// and the clip is not evidence of that moment; the day's grid is right
  /// there either way.
  void _jumpToMoment() {
    final moment = widget.initialTimestamp;
    if (moment == null || _jumpedToMoment || _isDemo) return;
    _jumpedToMoment = true;
    if (_replays.isEmpty) return;
    final nearest = nearestClipTo(_replays, moment);
    if (nearest == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.evidenceNoClip)));
      return;
    }
    _playVideo(nearest);
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
    var list = _replays;
    if (day != null) {
      final start = day.millisecondsSinceEpoch ~/ 1000;
      final end = start + 24 * 60 * 60;
      list = list.where((r) {
        final ts = (r['timestamp'] as num).toInt();
        return ts >= start && ts < end;
      }).toList();
    }
    final hour = _selectedHour;
    if (hour != null) {
      list = list.where((r) {
        final ts = (r['timestamp'] as num).toInt();
        return DateTime.fromMillisecondsSinceEpoch(ts * 1000).hour == hour;
      }).toList();
    }
    return list;
  }

  /// The day's 24 hours for the density strip. A missing endpoint (an
  /// older server) simply means no strip — the screen works without it.
  Future<void> _fetchDayHours(DateTime day) async {
    final key = _dayKey(day);
    if (_isDemo) {
      // Derive the strip from the synthetic clips — no server out there.
      final hours = List.generate(
        24,
        (h) => <String, dynamic>{'hour': h, 'total': 0, 'clips': 0},
      );
      for (final r in _replays) {
        final ts = (r['timestamp'] as num).toInt();
        final at = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        if (_dayKey(at) != key) continue;
        hours[at.hour]['clips'] = (hours[at.hour]['clips'] as int) + 1;
        hours[at.hour]['total'] = (hours[at.hour]['total'] as int) + 1;
      }
      if (mounted) setState(() => _dayHours = hours);
      return;
    }
    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/timeline/day?date=$key'),
            headers: AuthService.headers,
          )
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      // A day change mid-flight: the newer selection owns the strip.
      final current = _selectedDay == null ? null : _dayKey(_selectedDay!);
      if (current != key) return;
      final hours = response.statusCode == 200
          ? ((jsonDecode(response.body) as Map<String, dynamic>)['hours']
                    as List? ??
                [])
          : <dynamic>[];
      setState(() => _dayHours = hours);
    } catch (_) {
      if (mounted) setState(() => _dayHours = []);
    }
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
      filename: replay['filename'] as String?,
      pinned: replay['pinned'] == true,
    );
  }

  /// Pin = keep forever: the retention sweep and disk pressure both look away.
  /// Returns whether the server agreed, so the UI only flips on success.
  Future<bool> _togglePin(
    String filename,
    bool currentlyPinned,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final action = currentlyPinned ? 'unpin' : 'pin';
    try {
      final response = await http
          .post(
            Uri.parse(
              '${widget.serverIp}/api/replays/${Uri.encodeComponent(filename)}/$action',
            ),
            headers: AuthService.headers,
          )
          .timeout(const Duration(seconds: 4));
      if (!mounted) return false;
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final pinned = body['pinned'] == true;
      setState(() {
        for (final r in _replays) {
          if (r is Map && r['filename'] == filename) r['pinned'] = pinned;
        }
      });
      messenger.showSnackBar(
        SnackBar(content: Text(pinned ? l10n.clipPinned : l10n.clipUnpinned)),
      );
      return true;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.clipPinFailed)));
      return false;
    }
  }

  /// Ask first — this one is irreversible — then delete. True when the clip
  /// is gone, so the player can close over it.
  Future<bool> _confirmAndDeleteClip(
    String filename,
    AppLocalizations l10n,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteClipTitle),
        content: Text(l10n.deleteClipBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteClipConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return _deleteClip(filename, l10n);
  }

  /// Delete a clip now — the false alarm, the knocked-over camera. The pin
  /// goes with it on the server; here the row leaves the grid and the day
  /// strip stops counting it. Returns whether the server agreed.
  Future<bool> _deleteClip(String filename, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    // Remember the clip's day before it leaves, so the strip can follow.
    String? dayKey;
    for (final r in _replays) {
      if (r is Map && r['filename'] == filename) {
        final ts = (r['timestamp'] as num?)?.toInt();
        if (ts != null) {
          dayKey = _dayKey(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
        }
        break;
      }
    }
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${widget.serverIp}/api/replays/${Uri.encodeComponent(filename)}',
            ),
            headers: AuthService.headers,
          )
          .timeout(const Duration(seconds: 4));
      if (!mounted) return false;
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      setState(() {
        _replays.removeWhere((r) => r is Map && r['filename'] == filename);
        final bucket = dayKey == null
            ? null
            : _timelineByDay[dayKey] as Map<String, dynamic>?;
        if (bucket != null) {
          final clips = (bucket['clips'] as num?)?.toInt() ?? 0;
          if (clips > 0) bucket['clips'] = clips - 1;
        }
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.clipDeleted)));
      final selected = _selectedDay;
      if (selected != null) _fetchDayHours(selected);
      return true;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.clipDeleteFailed)));
      return false;
    }
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

  /// Share a link instead of the bytes: a week-long, file-scoped URL that
  /// opens in any browser on the network — for someone who has no session
  /// and no app. The server mints it; nothing long-lived goes in the message.
  Future<void> _shareLink(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final segments = Uri.parse(url).pathSegments;
      if (segments.isEmpty) throw Exception('no filename');
      final filename = segments.last;
      final response = await http
          .post(
            Uri.parse(
              '${widget.serverIp}/api/replays/'
              '${Uri.encodeComponent(filename)}/share',
            ),
            headers: AuthService.headers,
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final signedPath = body['url'] as String? ?? '';
      if (signedPath.isEmpty) throw Exception('no url in answer');
      await SharePlus.instance.share(
        ShareParams(
          text: '${l10n.shareInviteText}\n${widget.serverIp}$signedPath',
        ),
      );
    } catch (e) {
      debugPrint('clip link share failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  void _showVideoDialog({
    required String url,
    String? heroTag,
    String? filename,
    bool pinned = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    Widget player = Container(
      color: Colors.black,
      child: VideoPlayerWidget(videoUrl: url),
    );
    if (heroTag != null) player = Hero(tag: heroTag, child: player);
    // Hoisted out of the builder so setDialogState keeps the flipped star
    // instead of resetting it to the value the list had when the dialog opened.
    var isPinned = pinned;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: player),
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                        IconButton(
                          tooltip: l10n.shareLink,
                          onPressed: () => _shareLink(url),
                          icon: const Icon(Icons.link),
                        ),
                        if (filename != null)
                          IconButton(
                            tooltip: isPinned ? l10n.unpinClip : l10n.pinClip,
                            onPressed: () async {
                              final ok = await _togglePin(
                                filename,
                                isPinned,
                                l10n,
                              );
                              if (ok && mounted) {
                                setDialogState(() => isPinned = !isPinned);
                              }
                            },
                            icon: Icon(
                              isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                            ),
                          ),
                        if (filename != null)
                          IconButton(
                            tooltip: l10n.deleteClip,
                            onPressed: () async {
                              final navigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              final gone = await _confirmAndDeleteClip(
                                filename,
                                l10n,
                              );
                              if (gone && mounted) navigator.pop();
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
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
          );
        },
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
              onSelected: (_) => _selectDay(null),
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
    // The chips ride the page surface — theme ink keeps them readable in
    // light mode (white here made every day but today invisible).
    final ink = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _selectDay(isSelected ? null : day),
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
                style: TextStyle(
                  fontSize: 10,
                  color: ink.withValues(alpha: 0.54),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? AppColors.primary : ink,
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
                    Icon(
                      Icons.movie,
                      size: 10,
                      color: ink.withValues(alpha: 0.54),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$clips',
                      style: TextStyle(
                        fontSize: 10,
                        color: ink.withValues(alpha: 0.54),
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

  /// The selected day, hour by hour: how busy each one was. A tap filters
  /// the grid to that hour; the strip is the map of where the day happened.
  Widget _buildHourStrip(AppLocalizations l10n, ThemeData theme) {
    final ink = theme.colorScheme.onSurface;
    final totals = [
      for (final h in _dayHours) ((h['total'] as num?) ?? 0).toInt(),
    ];
    final maxTotal = totals.fold<int>(0, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.replaysHourStripTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: ink.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (_selectedHour != null)
                TextButton(
                  onPressed: () => setState(() => _selectedHour = null),
                  child: Text(l10n.replaysHourClear),
                ),
            ],
          ),
          SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in _dayHours)
                  _buildHourBar(h, maxTotal, ink: ink, l10n: l10n),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final h in _dayHours)
                Expanded(
                  child: Center(
                    child: Text(
                      // Sparse ticks: every six hours is enough to read
                      // the day without a wall of numbers.
                      (h['hour'] as int) % 6 == 0
                          ? hourLabel(h['hour'] as int)
                          : '',
                      style: TextStyle(
                        fontSize: 10,
                        color: ink.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourBar(
    Map<String, dynamic> hour,
    int maxTotal, {
    required Color ink,
    required AppLocalizations l10n,
  }) {
    final h = (hour['hour'] as num).toInt();
    final total = ((hour['total'] as num?) ?? 0).toInt();
    final selected = _selectedHour == h;
    return Expanded(
      child: Tooltip(
        message: l10n.replaysHourTooltip(hourLabel(h), total),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              setState(() => _selectedHour = _selectedHour == h ? null : h),
          child: Container(
            height: hourBarHeight(total, maxTotal),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : total > 0
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : ink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
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
                  if (replay['pinned'] == true)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Colors.amber.shade600,
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
              onAction: () => _selectDay(null),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchReplays(haptic: true),
              child: _buildReplayGrid(visible, l10n, theme, isDesktop),
            );
      content = Column(
        children: [
          _buildDayStrip(l10n, theme),
          if (_selectedDay != null && _dayHours.isNotEmpty)
            _buildHourStrip(l10n, theme),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
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
