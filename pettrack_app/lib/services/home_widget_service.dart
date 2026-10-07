import 'dart:io';
import 'dart:typed_data';

import 'package:home_widget/home_widget.dart';

/// Data pushed to the Android home-screen widget. The widget only ever
/// displays these values — every string is localized by the caller through
/// AppLocalizations, so nothing is hardcoded on the native side either.
class WidgetSnapshot {
  final String title;
  final String status;
  final String batteryLabel;
  final String emptyHint;
  final Uint8List? png;

  const WidgetSnapshot({
    required this.title,
    required this.status,
    required this.batteryLabel,
    required this.emptyHint,
    this.png,
  });
}

/// How often the widget may be refreshed with a new still. Frames arrive at
/// several per second; the home screen does not need to.
const Duration kWidgetRefreshInterval = Duration(seconds: 30);

/// True when enough time has passed since the last push for another one.
bool shouldPushWidget({
  required DateTime? lastPush,
  required DateTime now,
  Duration interval = kWidgetRefreshInterval,
}) {
  if (lastPush == null) return true;
  return now.difference(lastPush) >= interval;
}

class HomeWidgetService {
  static const String kSnapshotKey = 'snapshot';
  static const String kTitleKey = 'title';
  static const String kStatusKey = 'status';
  static const String kBatteryKey = 'battery';
  static const String kEmptyHintKey = 'empty_hint';

  DateTime? _lastPush;

  /// Whether a push would be accepted right now. Callers check this before
  /// doing any expensive work (like encoding a still).
  bool isDue({DateTime? now}) {
    return shouldPushWidget(lastPush: _lastPush, now: now ?? DateTime.now());
  }

  /// Hand [snapshot] to the home-screen widget. No-op outside Android (the
  /// iOS widget would need a separate WidgetKit extension).
  Future<void> push(WidgetSnapshot snapshot, {DateTime? now}) async {
    if (!Platform.isAndroid) return;
    final timestamp = now ?? DateTime.now();
    if (!shouldPushWidget(lastPush: _lastPush, now: timestamp)) return;
    _lastPush = timestamp;
    try {
      await HomeWidget.saveWidgetData<String>(kTitleKey, snapshot.title);
      await HomeWidget.saveWidgetData<String>(kStatusKey, snapshot.status);
      await HomeWidget.saveWidgetData<String>(
        kBatteryKey,
        snapshot.batteryLabel,
      );
      await HomeWidget.saveWidgetData<String>(
        kEmptyHintKey,
        snapshot.emptyHint,
      );
      final png = snapshot.png;
      if (png != null) {
        await HomeWidget.saveFile(kSnapshotKey, png, extension: 'png');
      }
      await HomeWidget.updateWidget(name: 'PetTrackHomeWidgetProvider');
    } catch (e) {
      // A missing widget must never take the dashboard down with it.
    }
  }
}
