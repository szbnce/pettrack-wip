import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:url_launcher/url_launcher.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import '../theme/colors.dart';
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

  Future<void> _fetchReplays() async {
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
    final l10n = AppLocalizations.of(context)!;
    // The server returns a signed, file-scoped URL (short-lived token).
    // Fallback for older servers: put the session token into the URL.
    final signedPath =
        replay['url'] as String? ?? '/api/replays/${replay['filename']}?token=${widget.token}';
    final url = '${widget.serverIp}$signedPath';
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
              Flexible(
                child: Container(
                  color: Colors.black,
                  child: VideoPlayerWidget(videoUrl: url),
                ),
              ),
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
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorStatus != 0 || _errorDetail.isNotEmpty) {
      final errorText = _errorStatus != 0
          ? l10n.replaysLoadError(_errorStatus)
          : l10n.replaysNetworkError(_errorDetail);
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(errorText, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchReplays,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    } else if (_replays.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noReplays,
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    } else {
      content = GridView.builder(
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
          );
        },
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
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchReplays,
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
            floatingActionButton: FloatingActionButton(
              onPressed: _fetchReplays,
              mini: true,
              child: const Icon(Icons.refresh),
            ),
            body: content,
          );
  }
}
