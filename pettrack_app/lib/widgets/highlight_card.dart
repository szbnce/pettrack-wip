import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'skeleton_box.dart';
import 'video_player_widget.dart';
import '../services/auth_service.dart';

/// "Today's recap" card.
///
/// Asks the server for the day's stitched highlight (`/api/highlight`) and,
/// when there is one, offers to play or share it. Days without motion simply
/// hide the card — an empty state would just be noise on the dashboard.
class HighlightCard extends StatefulWidget {
  final String serverIp;
  final String token;

  /// Injectable for tests; defaults to the real HTTP call.
  final Future<Map<String, dynamic>?> Function()? fetcher;

  const HighlightCard({
    super.key,
    required this.serverIp,
    required this.token,
    this.fetcher,
  });

  @override
  State<HighlightCard> createState() => _HighlightCardState();
}

class _HighlightCardState extends State<HighlightCard> {
  Map<String, dynamic>? _highlight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.fetcher != null
          ? await widget.fetcher!()
          : await _fetchFromServer();
      if (!mounted) return;
      setState(() {
        _highlight = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchFromServer() async {
    final response = await http
        .get(
          Uri.parse('${widget.serverIp}/api/highlight'),
          headers: AuthService.headers,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  String get _videoUrl => '${widget.serverIp}${_highlight!['url'] as String}';

  Future<void> _play() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _videoUrl;
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
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.close),
                    ),
                    TextButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share),
                      label: Text(l10n.highlightShare),
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

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(Uri.parse(_videoUrl));
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/pettrack_recap_${_highlight!['date']}.mp4',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonBox.tile(height: 96),
      );
    }
    final highlight = _highlight;
    if (highlight == null) return const SizedBox.shrink();

    final count = (highlight['clip_count'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _play,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF004945)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.movie_filter,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.highlightTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count > 0
                              ? l10n.highlightMoments(count)
                              : l10n.highlightSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
