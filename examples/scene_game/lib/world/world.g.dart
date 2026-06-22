// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

class $SetupWorldSystemAdapter implements SystemAdapter, SystemAccessProvider {
  $SetupWorldSystemAdapter(this._system);

  final SetupWorldSystem _system;
  late final Scene _p0;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<Scene>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0);
  }
}

/// Schedulable descriptor for [SetupWorldSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final setupWorldSystem = SystemDescriptor(
  const SystemRef('package:scene_game/world/world.dart', 'SetupWorldSystem'),
  () => $SetupWorldSystemAdapter(const SetupWorldSystem()),
);
