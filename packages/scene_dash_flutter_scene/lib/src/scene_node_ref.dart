import 'package:flutter_scene/scene.dart' show Node;
import 'package:scene_dash/scene_dash.dart';

/// An object component that binds an ECS entity to a `flutter_scene` [Node].
///
/// Transform synchronization writes the bound node's **local** transform;
/// `flutter_scene` then performs its own hierarchy/world-transform propagation.
///
/// Annotated `@ObjectComponent` so that game code which references it in
/// `@Bundle`/`@Query` is classified correctly by the generator. The integration
/// does not run code generation itself; it registers the store on demand.
@ObjectComponent()
final class SceneNodeRef {
  /// The bound scene-graph node.
  final Node node;

  const SceneNodeRef(this.node);
}

/// Tag marking an entity whose node transform is owned by physics (or another
/// authority), so generic ECS transform synchronization must skip it.
///
/// See "transform authority" in `docs/concept.md` §22: every bound node must
/// have exactly one transform source.
@Tag()
final class PhysicsDriven {
  const PhysicsDriven();
}

/// Integration-managed tag marking a [SceneNodeRef] entity whose node is mounted
/// in the scene graph.
///
/// **This is integration state, not something game code authors.** The scene
/// driver adds it when it mounts a bound node and removes it on unmount/despawn;
/// bundles must never include it. Normal gameplay systems do not need it either:
/// the integration guarantees nodes are mounted *before* the `update` phase runs
/// (see [Game]), so a queried [SceneNodeRef] reached from an update system is
/// already in the scene.
///
/// Filter on `Mounted` only for an advanced system that intentionally targets
/// scene-mounted entities while running in an unusual lifecycle phase.
@Tag()
final class Mounted {
  const Mounted();
}
