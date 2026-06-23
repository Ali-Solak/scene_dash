part of 'player.dart';

/// Startup: spawn the one player. A top-level `@System` function — the most
/// concise system form (no class, no constructor, no mixin). The generator emits
/// a `spawnPlayerSystem` descriptor for it.
@System()
void spawnPlayer(Commands commands) {
  commands.spawn(PlayerBundle());
}

/// Fixed step: translate input into a move-and-slide request.
///
/// Drives the player through its native character controller and snaps it to the
/// ramp (both reached through `SceneNodeRef`), so the query declares
/// `writes: [SceneNodeRef]`: mutating an object reached through a component
/// reference counts as writing that component for scheduler diagnostics.
@System()
void movePlayer(
  @Query(requires: [Player], writes: [SceneNodeRef])
  Single<SceneNodeRef> player,
  @Resource() InputState input,
  @Resource() GameState game,
  @Resource() FixedTime time,
) {
  if (game.status != GameStatus.playing) return;
  // The integration mounts the player under the RapierWorld before the first
  // step, so the node is already in the scene here.
  final node = player.value.node;
  final controller = node.getComponent<RapierKinematicCharacterController>();
  if (controller == null) return;

  _snapToRamp(node);

  final dt = time.delta;
  controller.move(Vector3(input.horizontal * playerStrafeSpeed * dt, 0, 0));
}

void _snapToRamp(Node node) {
  final position = node.localTransform.getTranslation();
  if (!isOverRampFootprint(position.x, position.z)) return;
  position.y = playerGroundYAtZ(position.z);
  node.localTransform = Matrix4.translation(position);
}
