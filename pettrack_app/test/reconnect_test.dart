import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/utils/reconnect.dart';

void main() {
  final t0 = DateTime(2026, 10, 9, 12);

  ReconnectPacer pacer() =>
      ReconnectPacer(random: Random(7)); // any seed — bounds, not values

  void expectWithin(Duration d, int ms) {
    expect(d.inMilliseconds, greaterThanOrEqualTo((ms * 0.8).floor()));
    expect(d.inMilliseconds, lessThanOrEqualTo((ms * 1.2).ceil()));
  }

  group('the curve', () {
    test('first failure retries almost at once', () {
      expectWithin(pacer().next(t0), 500);
    });

    test('a crash keeps slowing down to the cap', () {
      final p = pacer();
      // Every attempt dies instantly: opened() and next() share a moment.
      final curve = <int>[];
      for (var i = 0; i < 8; i++) {
        p.opened(t0);
        curve.add(p.next(t0).inMilliseconds);
      }
      expectWithin(Duration(milliseconds: curve[0]), 500);
      expectWithin(Duration(milliseconds: curve[1]), 1000);
      expectWithin(Duration(milliseconds: curve[2]), 2000);
      expectWithin(Duration(milliseconds: curve[3]), 4000);
      expectWithin(Duration(milliseconds: curve[4]), 8000);
      expectWithin(Duration(milliseconds: curve[5]), 15000);
      expectWithin(Duration(milliseconds: curve[6]), 15000);
      // The cap plus jitter is the absolute ceiling.
      for (final ms in curve) {
        expect(ms, lessThanOrEqualTo((15000 * 1.2).ceil()));
      }
    });

    test('a failed handshake never gets impatient again', () {
      final p = pacer();
      for (var i = 0; i < 20; i++) {
        p.next(t0); // no opened() — the server never answered
      }
      expectWithin(p.next(t0), 15000);
    });

    test('reset starts the curve over', () {
      final p = pacer();
      for (var i = 0; i < 5; i++) {
        p.next(t0);
      }
      p.reset();
      expectWithin(p.next(t0), 500);
    });
  });

  group('healthy connections', () {
    test('a long-lived connection ending in a blip retries fast', () {
      final p = pacer();
      p.opened(t0);
      // Blip after ten healthy minutes: the next wait is a fresh one.
      expectWithin(p.next(t0.add(const Duration(minutes: 10))), 500);
    });

    test('a connection that dies young keeps the curve growing', () {
      final p = pacer();
      p.opened(t0);
      p.next(t0.add(const Duration(seconds: 1))); // dead at 1s < 5s
      p.opened(t0.add(const Duration(seconds: 2)));
      expectWithin(p.next(t0.add(const Duration(seconds: 3))), 1000);
    });

    test('the healthy threshold is the boundary', () {
      final p = pacer();
      p.opened(t0);
      expectWithin(
        p.next(t0.add(p.healthyAfter - const Duration(milliseconds: 1))),
        500,
      );
      // The first one did not reset (young death), so this is attempt two.
      p.opened(t0);
      expectWithin(p.next(t0.add(p.healthyAfter)), 500);
    });

    test('each death consumes exactly one attempt', () {
      final p = pacer();
      p.opened(t0);
      p.next(t0);
      p.opened(t0);
      p.next(t0);
      p.opened(t0);
      p.next(t0);
      expectWithin(p.next(t0), 4000); // fourth wait of the curve
    });
  });
}
