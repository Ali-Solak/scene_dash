import 'package:flutter_test/flutter_test.dart';
import 'package:scene_game/game/config.dart';
import 'package:scene_game/projectiles/projectiles.dart';

/// Pure-logic coverage for the burst blaster's fire/cooldown state machine.
void main() {
  test('a fresh blaster can start a burst', () {
    expect(Blaster().canStartBurst, isTrue);
  });

  test('a burst fires exactly blasterBurstShots shots', () {
    final blaster = Blaster()..startBurst();
    expect(blaster.canStartBurst, isFalse, reason: 'a burst is in progress');

    var fired = 0;
    for (var i = 0; i < blasterBurstShots + 5; i++) {
      if (blaster.consumeShot(blasterBurstInterval)) fired++;
    }
    expect(fired, blasterBurstShots);
  });

  test('a new burst is blocked until the cooldown elapses', () {
    final blaster = Blaster()..startBurst();
    for (var i = 0; i < blasterBurstShots; i++) {
      blaster.consumeShot(blasterBurstInterval);
    }
    // Shots are spent but the cooldown is still running.
    expect(blaster.canStartBurst, isFalse);

    // Draining the cooldown (consumeShot decrements it even with no shots queued)
    // re-arms the blaster.
    blaster.consumeShot(blasterCooldown);
    expect(blaster.canStartBurst, isTrue);
  });

  test('reset re-arms the blaster immediately', () {
    final blaster = Blaster()
      ..startBurst()
      ..reset();
    expect(blaster.canStartBurst, isTrue);
  });
}
