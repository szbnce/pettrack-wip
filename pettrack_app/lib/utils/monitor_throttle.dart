/// Battery-aware stream pacing for the monitor phone.
///
/// A monitor that dies is blind. When the battery runs low and nothing is
/// charging it, the stream slows down instead — at the cost of coarser
/// motion detection, which is better than no camera at all.
library;

/// Below this (and not charging), the stream drops to half speed.
const monitorLowBatteryThreshold = 20;

/// Below this (and not charging), the stream drops to quarter speed.
const monitorCriticalBatteryThreshold = 10;

/// The frame interval in ms for a monitor at [batteryLevel] percent,
/// pacing the viewer's [baseFps] (0.5 fps is the plain default).
int frameIntervalMs({
  required double baseFps,
  required int batteryLevel,
  required bool isCharging,
}) {
  final fps = baseFps > 0 ? baseFps : 0.5;
  if (isCharging || batteryLevel > monitorLowBatteryThreshold) {
    return (1000 / fps).round();
  }
  if (batteryLevel > monitorCriticalBatteryThreshold) {
    return (1000 / (fps / 2)).round(); // half speed
  }
  return (1000 / (fps / 4)).round(); // quarter speed
}

/// Whether the throttle is doing anything right now — the UI says so
/// instead of streaming slower in silence.
bool isThrottled({required int batteryLevel, required bool isCharging}) =>
    !isCharging && batteryLevel <= monitorLowBatteryThreshold;
