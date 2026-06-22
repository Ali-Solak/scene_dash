// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

class $SpawnPlayerSystemAdapter implements SystemAdapter, SystemAccessProvider {
  $SpawnPlayerSystemAdapter(this._system);

  final SpawnPlayerSystem _system;
  late final Commands _p0;

  @override
  void initialize(World world) {
    _p0 = world.commands;
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0);
  }
}

/// Schedulable descriptor for [SpawnPlayerSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final spawnPlayerSystem = SystemDescriptor(
  const SystemRef('package:scene_game/player/player.dart', 'SpawnPlayerSystem'),
  () => $SpawnPlayerSystemAdapter(const SpawnPlayerSystem()),
);

class $MovePlayerSystemAdapter implements SystemAdapter, SystemAccessProvider {
  $MovePlayerSystemAdapter(this._system);

  final MovePlayerSystem _system;
  late final Query1<SceneNodeRef> _p0;
  late final InputState _p1;
  late final GameState _p2;
  late final FixedTime _p3;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    _p0 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Player],
      withoutTypes: const <Type>[],
    );
    _p1 = world.resources.get<InputState>();
    _p2 = world.resources.get<GameState>();
    _p3 = world.resources.get<FixedTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3);
  }
}

/// Schedulable descriptor for [MovePlayerSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final movePlayerSystem = SystemDescriptor(
  const SystemRef('package:scene_game/player/player.dart', 'MovePlayerSystem'),
  () => $MovePlayerSystemAdapter(const MovePlayerSystem()),
);

mixin _$PlayerBundle implements SceneDashBundle {
  @override
  void insertInto(World world, Entity entity) {
    final self = this as PlayerBundle;
    world.ensureTagStore<Player>().add(entity.index);
    world.ensureObjectStore<SceneNodeRef>().insert(entity.index, self.node);
    world.ensureTagStore<PhysicsDriven>().add(entity.index);
  }
}
