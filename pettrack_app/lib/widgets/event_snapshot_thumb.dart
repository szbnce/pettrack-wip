import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// A still frame from the moment an event happened, shown as a small thumb.
///
/// Zone entries save a snapshot on the server; zone exits and sound events
/// do not, so this collapses to nothing when the server says 404. The feed
/// row keeps its shape either way — a missing thumb is not an error.
class EventSnapshotThumb extends StatelessWidget {
  const EventSnapshotThumb({
    super.key,
    required this.serverIp,
    required this.timestamp,
    this.size = 48,
  });

  final String serverIp;
  final int timestamp;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        '$serverIp/api/event/snapshot/$timestamp',
        headers: AuthService.headers,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // No snapshot, or the server is mid-restart: no thumb, no error row.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
