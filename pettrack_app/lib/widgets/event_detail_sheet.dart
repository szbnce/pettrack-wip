import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

/// The moment, not the log line.
///
/// Tapping an event used to jump straight into the clip, which is right for
/// "show me now" and wrong for "what actually happened?" — the still frame
/// and the plain words never got a look in. This sheet is the pause before
/// that jump: what the camera saw, said the way a person would say it, and
/// the few things you might want to do about it.
Future<void> showEventDetailSheet({
  required BuildContext context,
  required String serverIp,
  required Map<String, dynamic> event,
  required IconData icon,
  required Color color,
  required String title,
  required String subtitle,
  required VoidCallback onWatchClip,
  VoidCallback? onTeach,
  VoidCallback? onShare,
}) {
  final l10n = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  final ts = (event['timestamp'] as num?)?.toInt();
  final hasSnapshot = event['has_snapshot'] == true && ts != null;
  final zone = event['zone_name'] as String?;
  final when = ts == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(ts * 1000);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The frame is the evidence. Big, or absent — never a grey box
              // pretending to be one.
              if (hasSnapshot)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    '$serverIp/api/event/snapshot/$ts',
                    headers: AuthService.headers,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        _frameFallback(context, icon: icon, color: color),
                  ),
                )
              else
                _frameFallback(context, icon: icon, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (when != null)
                    _chip(
                      context,
                      icon: Icons.schedule,
                      label: _whenLabel(l10n, when),
                    ),
                  if (zone != null && zone.isNotEmpty)
                    _chip(context, icon: Icons.place, label: zone),
                  if (event['event_type'] == 'sound_detected')
                    _chip(
                      context,
                      icon: Icons.volume_up,
                      label: l10n.soundDetectedTitle,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onWatchClip();
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.eventWatchClip),
              ),
              if (onShare != null || onTeach != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onShare != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            onShare();
                          },
                          icon: const Icon(Icons.share_outlined),
                          label: Text(l10n.tooltipShare),
                        ),
                      ),
                    if (onShare != null && onTeach != null)
                      const SizedBox(width: 8),
                    if (onTeach != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            onTeach();
                          },
                          icon: const Icon(Icons.school_outlined),
                          label: Text(l10n.feedbackTitle),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// What the moment looked like when the camera kept nothing. The words live
/// below, once — a panel that repeats the headline reads like two headlines.
Widget _frameFallback(
  BuildContext context, {
  required IconData icon,
  required Color color,
}) {
  return Container(
    height: 160,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, size: 56, color: color),
  );
}

Widget _chip(
  BuildContext context, {
  required IconData icon,
  required String label,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

/// A moment is "14:20" to a log and "Today at 14:20" to a person. Keep the
/// day when it is not obvious from the list around it.
String _whenLabel(AppLocalizations l10n, DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(when.year, when.month, when.day);
  final time = '${when.hour}:${when.minute.toString().padLeft(2, '0')}';
  final days = today.difference(thatDay).inDays;
  if (days == 0) return '${l10n.eventToday} · $time';
  if (days == 1) return '${l10n.eventYesterday} · $time';
  final month = when.month.toString().padLeft(2, '0');
  final day = when.day.toString().padLeft(2, '0');
  return '${when.year}-$month-$day · $time';
}
