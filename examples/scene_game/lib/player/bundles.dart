part of 'player.dart';

/// The player: a kinematic sphere driven by Rapier's character controller.
///
/// The node carries everything physics needs, and [PhysicsDriven] tells the
/// integration's generic transform sync to leave it alone. The controller owns
/// the transform while playing; after a hit, rules keep the body kinematic, zero
/// its velocities, and drive an authored `ImpactMotion` transform for the
/// visible tumble.
@Bundle()
final class PlayerBundle with _$PlayerBundle {
  final Player player;
  final SceneNodeRef node;
  final PhysicsDriven physics;

  PlayerBundle()
    : player = const Player(),
      node = SceneNodeRef(_makeNode()),
      physics = const PhysicsDriven();

  static Node _makeNode() {
    final playerMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(0.05, 0.54, 1.0, 1)
      ..metallicFactor = 0.28
      ..roughnessFactor = 0.18
      ..emissiveFactor = Vector4(0.0, 0.14, 0.32, 1);
    final markerMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(1, 1, 1, 1)
      ..metallicFactor = 0.12
      ..roughnessFactor = 0.2
      ..emissiveFactor = Vector4(0.55, 0.72, 1.0, 1);

    return Node(
        mesh: Mesh(SphereGeometry(radius: playerRadius), playerMaterial),
        localTransform: Matrix4.translation(
          Vector3(0, playerStartY, playerStartZ),
        ),
      )
      ..add(
        Node(
          mesh: Mesh(
            CuboidGeometry(Vector3(0.18, 0.18, playerRadius * 1.6)),
            markerMaterial,
          ),
          localTransform: Matrix4.translation(Vector3(0, playerRadius, 0)),
        ),
      )
      ..addComponent(RapierRigidBody(type: BodyType.kinematic))
      ..addComponent(
        RapierCollider(
          shape: SphereShape(radius: playerRadius),
          collisionLayer: PhysicsLayers.player,
        ),
      )
      ..addComponent(
        RapierKinematicCharacterController(
          up: Vector3(0, 1, 0),
          slide: true,
          snapToGround: 0.5,
          autostep: true,
        ),
      );
  }
}
