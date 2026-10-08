import 'dart:math';

/// Reconnect pacing for every socket in the app.
///
/// A blip should cost a blink; a dead server should not get hammered.
/// So each failure waits exponentially longer (capped, jittered so a fleet
/// of clients does not stampede back at once), while a connection that was
/// up long enough to count as healthy resets the curve — the next blip
/// retries fast again.
class ReconnectPacer {
  ReconnectPacer({
    this.base = const Duration(milliseconds: 500),
    this.cap = const Duration(seconds: 15),
    this.healthyAfter = const Duration(seconds: 5),
    Random? random,
  }) : _random = random ?? Random();

  /// The wait after the first failure; doubles from there.
  final Duration base;

  /// The longest wait the curve ever reaches.
  final Duration cap;

  /// A connection that survived this long was a healthy one whose end was
  /// just a blip. Shorter than this and it was a crash — keep slowing down.
  final Duration healthyAfter;

  final Random _random;
  int _attempts = 0;
  DateTime? _openedAt;

  /// The handshake worked. If the connection lives past [healthyAfter],
  /// its eventual death starts the curve over.
  void opened([DateTime? at]) {
    _openedAt = at ?? DateTime.now();
  }

  /// The connection is gone — how long to wait before the next attempt.
  Duration next([DateTime? at]) {
    final now = at ?? DateTime.now();
    final openedAt = _openedAt;
    _openedAt = null;
    if (openedAt != null && now.difference(openedAt) >= healthyAfter) {
      _attempts = 0;
    }
    return _delayFor(_attempts++);
  }

  /// Start the curve over — for a fresh stream the user just asked for.
  void reset() {
    _attempts = 0;
    _openedAt = null;
  }

  Duration _delayFor(int attempt) {
    final expMs = base.inMilliseconds * (1 << min(attempt, 16));
    final cappedMs = min(expMs, cap.inMilliseconds);
    // ±20% so simultaneous clients spread out.
    final jitter = 0.8 + 0.4 * _random.nextDouble();
    return Duration(milliseconds: max(1, (cappedMs * jitter).round()));
  }
}
