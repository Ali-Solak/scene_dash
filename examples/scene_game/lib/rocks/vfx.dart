part of 'rocks.dart';

/// A deliberately tiny world-space trail for the fast rocks.
///
/// The puffs are mounted under the scene root, so they do not inherit the
/// rock's rolling transform. Keeping this to three opaque instances avoids the
/// previous particle-emitter cost on mobile.
final class FlameTrail extends Component {
  static const int _puffCount = 3;

  static final Geometry _geometry = SphereGeometry(
    radius: 1,
    segments: 8,
    rings: 4,
  );

  static final Material _material = UnlitMaterial()
    ..baseColorFactor = Vector4(1.0, 0.34, 0.05, 1)
    ..vertexColorWeight = 0;

  final InstancedMesh _mesh = InstancedMesh(
    geometry: _geometry,
    material: _material,
  );
  final Vector3 _lastPosition = Vector3.zero();
  final Vector3 _direction = Vector3(0, 0, 1);
  final Vector3 _trailPosition = Vector3.zero();
  final Matrix4 _transform = Matrix4.identity();
  bool _hasLastPosition = false;
  Node? _trail;

  @override
  void onMount() {
    for (var i = 0; i < _puffCount; i++) {
      _mesh.addInstance(_hiddenTransform);
    }
    final trail = Node(name: 'flame trail')
      ..addComponent(InstancedMeshComponent(_mesh));
    node.getRoot().add(trail);
    _trail = trail;
  }

  @override
  void onUnmount() {
    _trail?.detach();
    _trail = null;
    _mesh.clearInstances();
    _hasLastPosition = false;
  }

  @override
  void update(double deltaSeconds) {
    final position = node.globalTransform.getTranslation();
    if (_hasLastPosition) {
      _direction
        ..setFrom(position)
        ..sub(_lastPosition);
      if (_direction.length2 < 0.0001) {
        _direction.setValues(0, 0, 1);
      } else {
        _direction.normalize();
      }
    } else {
      _hasLastPosition = true;
    }
    _lastPosition.setFrom(position);

    for (var i = 0; i < _puffCount; i++) {
      final t = (i + 1).toDouble();
      final distance = rockRadius * 0.55 * t;
      _trailPosition
        ..setFrom(position)
        ..x -= _direction.x * distance
        ..y += rockRadius * (0.12 + 0.08 * i) - _direction.y * distance
        ..z -= _direction.z * distance;
      final size = rockRadius * (0.34 - i * 0.07);
      _transform
        ..setIdentity()
        ..setTranslation(_trailPosition)
        ..scaleByDouble(size, size, size, 1);
      _mesh.setInstanceTransform(i, _transform);
    }
  }
}

final Matrix4 _hiddenTransform = Matrix4.translation(Vector3(0, -9999, 0));
