import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:url_launcher/url_launcher.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/video_player_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchReplays();
  }

  Future<void> _fetchReplays({bool haptic = false}) async {
    setState(() {
      _isLoading = true;
      _errorStatus = 0;
      _errorDetail = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/replays'),
            headers: {'x-api-token': widget.token},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _replays = data['replays'] ?? [];
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
      setState(() {
        _errorDetail = e.toString();
        _isLoading = false;
      });
    }
  }

  void _playVideo(Map<String, dynamic> replay) {
    // The server returns a signed, file-scoped URL (short-lived token).
    // Fallback for older servers: put the session token into the URL.
    final signedPath =
        replay['url'] as String? ?? '/api/replays/${replay['filename']}?token=${widget.token}';
    _showVideoDialog(
      url: '${widget.serverIp}$signedPath',
      heroTag: 'replay-${replay['filename']}',
    );
  }

  /// Build today's timelapse on the server (cached there) and play it.
  Future<void> _openTimelapse() async {
    final l10n = AppLocalizations.of(context)!;
    // ffmpeg can take a while on a first build — show that we are working.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
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
              Text(l10n.timelapseBuilding, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/timelapse'),
            headers: {'x-api-token': widget.token},
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
    } else if (_replays.isEmpty) {
      content = EmptyState(
        icon: Icons.videocam_off_outlined,
        title: l10n.noReplays,
        textColor: Colors.white54,
        iconColor: Colors.white24,
        actionLabel: l10n.retry,
        onAction: () => _fetchReplays(haptic: true),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: () => _fetchReplays(haptic: true),
        child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 16 / 9,
        ),
        itemCount: _replays.length,
        itemBuilder: (context, index) {
          final replay = _replays[index];
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
        ),
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
                          onPressed: _openTimelapse,
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
                  onPressed: _openTimelapse,
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
