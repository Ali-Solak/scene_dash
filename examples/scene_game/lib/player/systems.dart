part of 'player.dart';

/// Startup: spawn the one player.
@System()
final class SpawnPlayerSystem extends GameSystem {
  const SpawnPlayerSystem();

  void run(Commands commands) {
    commands.spawn(PlayerBundle());
  }
}

/// Fixed step: translate input into a move-and-slide request.
@System()
final class MovePlayerSystem extends GameSystem {
  const MovePlayerSystem();

  void run(
    @Query(requires: [Player]) Query1<SceneNodeRef> players,
    @Resource() InputState input,
    @Resource() GameState game,
    @Resource() FixedTime time,
  ) {
    if (game.status != GameStatus.playing) return;
    players.each((entity, binding) {
      final node = binding.node;
      // The integration mounts the player under the RapierWorld before the first
      // step, so the node is already in the scene here.
      final controller = node
          .getComponent<RapierKinematicCharacterController>();
      if (controller == null) return;

      _snapToRamp(node);

      final dt = time.delta;
      controller.move(Vector3(input.horizontal * playerStrafeSpeed * dt, 0, 0));
    });
  }

  void _snapToRamp(Node node) {
    final position = node.localTransform.getTranslation();
    if (!isOverRampFootprint(position.x, position.z)) return;
    position.y = playerGroundYAtZ(position.z);
    node.localTransform = Matrix4.translation(position);
  }
}
