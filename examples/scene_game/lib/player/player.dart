import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../game/config.dart';
import '../game/game_state.dart';

part 'player.g.dart';
part 'components.dart';
part 'bundles.dart';
part 'systems.dart';

/// Installs the player feature.
@GamePlugin()
final class PlayerPlugin extends Plugin {
  const PlayerPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(spawnPlayerSystem, schedule: Schedules.startup)
      ..addSystem(movePlayerSystem, schedule: Schedules.fixedPrePhysics);
  }
}
