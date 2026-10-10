import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';

class VideoPlayerWidget extends StatefulWidget {
  /// Signed, file-scoped replay URL (the server embeds a short-lived token).
  final String videoUrl;

  /// Where in the clip to start: the moment the event happened, not the
  /// opening frame. Clamped to the clip's own length once it is known.
  final Duration? startAt;

  const VideoPlayerWidget({super.key, required this.videoUrl, this.startAt});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize()
          .then((_) {
            if (!mounted) return;
            // Land on the event, not the first frame — but never past the end.
            final startAt = widget.startAt;
            if (startAt != null && startAt > Duration.zero) {
              final duration = _controller.value.duration;
              _controller.seekTo(startAt > duration ? duration : startAt);
            }
            setState(() {
              _initialized = true;
            });
            _controller.play();
            _controller.setLooping(true);
          })
          .catchError((error) {
            if (!mounted) return;
            setState(() {
              _error = true;
            });
          });
  }

  /// Clips can fail to start (expired signed URL, flaky Wi-Fi) — say so and
  /// let the viewer try again instead of showing a bare error icon.
  Future<void> _retry() async {
    setState(() {
      _error = false;
      _initialized = false;
    });
    try {
      await _controller.dispose();
    } catch (_) {}
    _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(l10n.videoLoadError),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _retry, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Semantics(
          button: true,
          label: l10n.tooltipPlayPause,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          right: 10,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.green,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white12,
            ),
          ),
        ),
      ],
    );
  }
}
