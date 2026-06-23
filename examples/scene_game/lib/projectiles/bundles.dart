part of 'projectiles.dart';

@Bundle()
final class ProjectileBundle with _$ProjectileBundle {
  ProjectileBundle({required Vector3 position})
    : projectile = Projectile(),
      node = SceneNodeRef(_makeNode(position));

  final Projectile projectile;
  final SceneNodeRef node;
  final PhysicsDriven physics = const PhysicsDriven();

  // Every projectile is visually identical, so its geometry and materials never
  // change between spawns — build them once and share them instead of rebuilding
  // engine geometry and buffers on each high-churn spawn.
  static final Material _material = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.5, 0.9, 1.0, 1)
    ..emissiveFactor = Vector4(0.3, 0.85, 1.0, 1)
    ..metallicFactor = 0.08
    ..roughnessFactor = 0.18;
  static final Material _glowMaterial = glowMaterial(
    Vector4(0.38, 0.9, 1.0, 0.42),
    alpha: 0.42,
  );
  static final Material _trailMaterial = glowMaterial(
    Vector4(0.18, 0.55, 1.0, 0.2),
    alpha: 0.2,
  );
  static final _geometry = SphereGeometry(radius: projectileRadius);
  static final _glowGeometry = SphereGeometry(radius: projectileRadius * 1.35);
  static final _trailGeometry = CuboidGeometry(Vector3(0.07, 0.07, 0.78));

  static Node _makeNode(Vector3 position) {
    return Node(
        mesh: Mesh(_geometry, _material),
        localTransform: Matrix4.translation(position),
      )
      ..frustumCulled = false
      ..add(
        Node(mesh: Mesh(_glowGeometry, _glowMaterial))..frustumCulled = false,
      )
      ..add(
        Node(
          mesh: Mesh(_trailGeometry, _trailMaterial),
          localTransform: Matrix4.translation(Vector3(0, 0, 0.38)),
        )..frustumCulled = false,
      )
      ..addComponent(
        RapierRigidBody(
          type: BodyType.dynamic_,
          mass: 0.04,
          ccdEnabled: true,
          linearVelocity: Vector3(0, projectileLaunchUp, -projectileSpeed),
          linearDamping: 0,
        ),
      )
      ..addComponent(
        RapierCollider(
          shape: SphereShape(radius: projectileRadius),
          isTrigger: true,
        ),
      );
  }
}
