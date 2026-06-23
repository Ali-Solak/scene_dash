import 'package:flutter_test/flutter_test.dart';
import 'package:scene_game/game/config.dart';
import 'package:scene_game/rules/rules.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

/// Pure-logic coverage for the authored post-hit tumble (no scene or GPU).
void main() {
  test('a fresh ImpactMotion is inactive and advancing is a no-op', () {
    final impact = ImpactMotion()..advance(0.1);
    expect(impact.active, isFalse);
    expect(impact.position.x, 0);
    expect(impact.position.y, 0);
    expect(impact.position.z, 0);
  });

  test('start launches up and away from the rock', () {
    final impact = ImpactMotion()
      ..start(
        playerPosition: Vector3(0, 5, 0),
        rockPosition: Vector3(0, 5, -1),
      );
    expect(impact.active, isTrue);
    expect(impact.position.y, 5);
    expect(impact.velocity.y, closeTo(knockbackUp, 1e-9));
    // The rock is behind the player (-z), so the knock pushes the player +z.
    expect(impact.velocity.z, closeTo(knockbackHorizontal, 1e-6));
  });

  test('advance applies gravity to the vertical velocity', () {
    final impact = ImpactMotion()
      ..start(
        playerPosition: Vector3(0, 5, 0),
        rockPosition: Vector3(0, 5, -1),
      );
    final before = impact.velocity.y;
    impact.advance(0.05);
    expect(impact.velocity.y, lessThan(before));
  });

  test('reset deactivates and zeroes the motion', () {
    final impact = ImpactMotion()
      ..start(playerPosition: Vector3(2, 5, 1), rockPosition: Vector3(0, 5, 0))
      ..advance(0.05)
      ..reset();
    expect(impact.active, isFalse);
    expect(impact.position.length, 0);
    expect(impact.velocity.length, 0);
    expect(impact.spin, 0);
  });
}
