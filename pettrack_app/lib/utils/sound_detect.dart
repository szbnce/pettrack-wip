/// Sound-event detection for the monitor phone.
///
/// The monitor only measures loudness (dBFS) with the microphone — it never
/// records or uploads audio. A sample at or above the threshold is treated as
/// a "loud noise" event (a bark, a meow, something knocked over).
library;

/// dBFS loudness at which a sample counts as a sound event.
///
/// -50 is a quiet room, -25 is normal speech, a close bark lands around -15.
const double kSoundThresholdDb = -25.0;

/// How long the monitor waits before reporting another sound event.
const Duration kSoundReportCooldown = Duration(seconds: 30);

/// True when [currentDb] is loud enough to be worth an event.
bool isSoundLevelEvent(
  double currentDb, {
  double threshold = kSoundThresholdDb,
}) {
  return currentDb >= threshold;
}
