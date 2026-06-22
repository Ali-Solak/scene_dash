part of 'rules.dart';

final class ImpactMotion {
  final Vector3 position = Vector3.zero();
  final Vector3 velocity = Vector3.zero();
  double spin = 0;
  bool active = false;

  void start({required Vector3 playerPosition, required Vector3 rockPosition}) {
    final away = playerPosition - rockPosition;
    away.y = 0;
    if (away.length2 < 0.001) {
      away.setValues(0, 0, 1);
    } else {
      away.normalize();
    }

    active = true;
    spin = 0;
    position.setFrom(playerPosition);
    velocity.setValues(
      away.x * knockbackHorizontal,
      knockbackUp,
      away.z * knockbackHorizontal,
    );
  }

  void reset() {
    active = false;
    spin = 0;
    position.setZero();
    velocity.setZero();
  }

  void advance(double dt) {
    if (!active) return;
    velocity.y -= impactGravity * dt;
    position
      ..x += velocity.x * dt
      ..y += velocity.y * dt
      ..z += velocity.z * dt;
    final groundY = playerGroundYAtZ(position.z);
    if (isOverRampFootprint(position.x, position.z) && position.y < groundY) {
      position.y = groundY;
      if (velocity.y < 0) {
        velocity.y = 0;
      }
    }
    spin += impactSpinSpeed * dt;
  }

  Matrix4 transform() {
    return Matrix4.translation(position)
      ..rotateX(spin)
      ..rotateZ(spin * 0.65);
  }
}
