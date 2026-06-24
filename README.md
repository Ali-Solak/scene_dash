# Scene-Dash

## Early prerelease

Scene-Dash is under active development. APIs may change between development
releases. It is published for experimentation, examples, and design feedback.

Scene-Dash is a Bevy-inspired game framework built on
[`flutter_scene`](https://pub.dev/packages/flutter_scene). It uses an
object-based ECS designed for Dart: components are ordinary mutable objects,
queries return direct references, and generated adapters handle system and
bundle wiring without runtime reflection.

Scene-Dash **complements** `flutter_scene`; it does not replace its scene graph,
renderer, cameras, nodes, physics world, or frame loop. The integration lets ECS
systems work directly with those native objects. The ECS core can also run
independently of Flutter for headless tests and simulations.

The [`scene_game` example](examples/scene_game) is the most complete reference.
Its [feature-oriented layout](examples/scene_game/lib) shows how a real game is
split into focused areas — each folder is one plugin that owns its components,
bundles, systems, and resources:

```text
lib/
├── player/        # one feature = one plugin
├── projectiles/
├── rocks/
├── collectables/
├── world/
├── hud/
└── main.dart      # builds the Scene, the Game, and adds every plugin
```

## Table of Contents

- [The shape of a Scene-Dash game](#the-shape-of-a-scene-dash-game)
- [Quick Start](#quick-start)
- [Building a game, top-down](#building-a-game-top-down)
  - [1. Plugins — one feature, one plugin](#1-plugins--one-feature-one-plugin)
  - [2. Systems — your behaviour](#2-systems--your-behaviour)
  - [3. Tags and components — the data systems query](#3-tags-and-components--the-data-systems-query)
  - [4. Bundles — spawn recipes (tags included)](#4-bundles--spawn-recipes-tags-included)
  - [5. Events — decoupled messages](#5-events--decoupled-messages)
  - [6. Resources — shared state (and a save repo)](#6-resources--shared-state-and-a-save-repo)
- [Rendering: the `flutter_scene` integration](#rendering-the-flutter_scene-integration)
- [Physics with Rapier](#physics-with-rapier)
- [Packages and Examples](#packages-and-examples)
- [Verification](#verification)

## The shape of a Scene-Dash game

Everything flows from the app downward:

- create a `flutter_scene` `Scene`;
- wrap it in a `Game`;
- add **plugins** (one per feature);
- each plugin registers **systems**;
- systems **query** ordinary Dart objects and mutate the scene.

Here is the whole loop in one runnable file — a single orbiting cube:

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

part 'main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Scene.initializeStaticResources();

  final scene = Scene();
  final game = Game(scene: scene)..addPlugin(const CubeOrbitPlugin());
  await game.start();

  runApp(
    MaterialApp(
      home: Scaffold(
        body: SceneView(scene, cameraBuilder: _camera, onTick: game.onTick),
      ),
    ),
  );
}

Camera _camera(Duration elapsed) =>
    PerspectiveCamera(position: Vector3(0, 3, -6), target: Vector3.zero());

@GamePlugin()
final class CubeOrbitPlugin extends Plugin {
  const CubeOrbitPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(spawnCubeSystem, schedule: Schedules.startup)
      ..addSystem(orbitCubesSystem, schedule: Schedules.update);
  }
}

@System()
void spawnCube(Commands commands) => commands.spawn(CubeBundle());

@System()
void orbitCubes(
  @Query(writes: [SceneTransform, Orbit]) Query2<SceneTransform, Orbit> movers,
  @Resource() FrameTime time,
) {
  movers.each((entity, transform, orbit) {
    orbit.phase += orbit.speed * time.delta;
    transform
      ..x = orbit.radius * cos(orbit.phase)
      ..z = orbit.radius * sin(orbit.phase);
  });
}

@ObjectComponent()
final class Orbit {
  final double radius;
  final double speed;
  double phase;
  Orbit({required this.radius, required this.speed, this.phase = 0});
}

@Bundle()
final class CubeBundle with _$CubeBundle {
  static final Mesh mesh = Mesh(CuboidGeometry(Vector3.all(0.8)), UnlitMaterial());

  final SceneTransform transform = SceneTransform.zero();
  final Orbit orbit = Orbit(radius: 2, speed: 1);
  final SceneNodeRef node = SceneNodeRef(Node(mesh: mesh));
}
```

`Game` drives the schedules from `SceneView`. Startup spawns one entity carrying
a `SceneTransform`, an `Orbit`, and a `SceneNodeRef`; the integration mounts the
node and syncs the transform to `flutter_scene` every frame.

The annotations (`@System`, `@Bundle`, …) are turned into wiring code by
`build_runner`:

```bash
dart run build_runner build
```

The same ECS core runs **without Flutter** for headless tests and simulations —
swap `Game`/`SceneView` for a bare `App`:

```dart
final app = App()..addPlugin(const CubeOrbitPlugin());
app.start();
app.runSchedule(Schedules.update);
```

## Quick Start

This repository is a Dart pub workspace. Because the scene integration depends on
Flutter and `flutter_scene`, resolve it from the root with Flutter:

```bash
flutter pub get
```

Generated systems, plugin metadata, and bundles use `build_runner`:

```bash
cd examples/headless_example
dart run build_runner build
dart test
```

To run a Flutter scene example:

```bash
cd examples/scene_game
flutter run --enable-flutter-gpu
```

## Building a game, top-down

A Scene-Dash game is a set of features, and **each feature is a plugin**. This
tour goes top-down: start with the plugin that defines a feature, drill into the
systems it registers, then the data those systems touch, and finish with how
features talk to each other and persist. The running example is a player that
strafes and takes damage. Every generated source file starts the same way:

```dart
import 'package:scene_dash/scene_dash.dart';

part 'game.g.dart';
```

### 1. Plugins — one feature, one plugin

A **plugin** is the entry point for a feature: it registers that feature's
systems, resources, and events, and declares which schedule each system runs in.
Read a plugin top-to-bottom and you see the whole feature at a glance. Plugins can
require other plugins.

```dart
@GamePlugin(requires: [InputPlugin])
final class PlayerPlugin extends Plugin with _$PlayerPlugin {
  const PlayerPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(spawnPlayerSystem, schedule: Schedules.startup)            // §2
      ..addSystem(movePlayerSystem, schedule: Schedules.fixedPrePhysics)     // sets velocity
      ..addSystem(applyVelocitySystem, schedule: Schedules.fixedPrePhysics); // integrates it
  }
}
```

A plugin also registers events (`app.addEvent<EnemyKilled>()`, §5) and resources
(`app.insertResource<SaveRepo>(...)`, §6) for its feature.

Built-in schedules, in frame order: `frameStart`, `fixedPrePhysics` (each fixed
step, before the physics step — use `FixedTime`), `update` (every frame — use
`FrameTime`), `renderSync` (transform sync), plus `startup` and `shutdown` which
run once. A system reads the clock that matches its schedule — `FixedTime` in
`fixedPrePhysics`, `FrameTime` in `update`. Access-conflict diagnostics can warn
or error when unordered systems both write the same component, or one writes what
another reads.

`main` builds the `Scene` and `Game` and adds every plugin — the top of the whole
program (condensed from the `scene_game` example):

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Scene.initializeStaticResources();

  final scene = Scene();
  final game = Game(scene: scene)
    ..addPlugin(const InputPlugin())
    ..addPlugin(const PlayerPlugin())
    ..addPlugin(const EnemyPlugin());
  await game.start();

  runApp(MyGameApp(scene: scene, game: game));
}
```

`SceneView(scene, cameraBuilder: ..., onTick: game.onTick)` renders it. Call
`game.shutdown()` when the widget is disposed (it runs the `shutdown` schedule and
detaches the driver — important for hot restart and navigation).

### 2. Systems — your behaviour

A `@System` is what a plugin registers: it reads resources and **queries**, then
mutates components. It comes in two forms that generate the same kind of
descriptor (`spawnPlayer` → `spawnPlayerSystem`).

A **top-level function** — the most concise form, no class or constructor:

```dart
@System()
void spawnPlayer(Commands commands) {
  commands.spawn(PlayerBundle()); // bundle defined in §4
}
```

A **class** that `extends GameSystem` — when a system needs its own fields/state:

```dart
@System()
final class MovePlayerSystem extends GameSystem {
  const MovePlayerSystem();

  void run(
    @Query(requires: [Player], writes: [Velocity]) Single<Velocity> player,
    @Resource() InputState input,
  ) {
    player.value.x = input.horizontal * 5.0;
  }
}
```

**Queries** select entities that have a set of components and hand your callback
the components directly. Declare `writes:` for components you mutate so the
scheduler can detect conflicts; `requires:`/`excludes:` filter without appearing
in the callback:

```dart
@System()
void applyVelocity(
  @Query(writes: [SceneTransform], excludes: [Stunned])
  Query2<SceneTransform, Velocity> movers,
  @Resource() FixedTime time,
) {
  movers.each((entity, transform, velocity) {
    transform
      ..x += velocity.x * time.delta
      ..z += velocity.z * time.delta;
  });
}
```

For an entity that should be **unique** (the player, a camera rig), inject a
`Single<A>` instead of looping — it resolves the one match and throws on zero or
many. `OptionalSingle<A>` allows zero (`.valueOrNull`) but still rejects many;
`Query1..4` also expose `single()`, `singleOrNull()`, and `isEmpty`.

**Structural changes** (spawn, despawn, add/remove component) go through
`Commands` and are **deferred** to a safe schedule boundary, so removal never
invalidates a running query:

```dart
@System()
void spawnEnemy(Commands commands) {
  final enemy = commands.spawn();
  commands
      .entity(enemy)
      .insert(const Enemy())
      .insert(Health(30))
      .insert(Velocity(0, -2))      // drifts forward; applyVelocity integrates it
      .insert(SceneTransform.zero());
  // commands.remove<Stunned>(enemy);
  // commands.despawn(enemy);        // also deferred to the next safe boundary
}
```

### 3. Tags and components — the data systems query

Those queries filter and mutate two kinds of data.

`@Tag()` is a marker with **no per-entity payload** — it answers "is this entity
a …?" (player/enemy/team/state markers used in `requires:`/`excludes:`):

```dart
@Tag()
final class Player {
  const Player();
}

@Tag()
final class Enemy {
  const Enemy();
}
```

`@ObjectComponent()` is the normal component: each entity stores a reference to an
ordinary Dart object, and systems mutate it in place — no snapshots, proxies, or
reconstruction:

```dart
@ObjectComponent()
final class Health {
  double current;
  final double max;
  Health(this.max) : current = max;
}

@ObjectComponent()
final class Velocity {
  double x;
  double z;
  Velocity(this.x, this.z);
}
```

Rule of thumb: if it stores values, it's an `@ObjectComponent`; if it only
classifies, it's a `@Tag`.

### 4. Bundles — spawn recipes (tags included)

`@Bundle()` is a typed spawn recipe: mix in `_$YourBundle` and one
`commands.spawn(bundle)` inserts **every field** as a component.

A bundle mixes data components and tags freely. A `@Tag` has no payload, so you
include it as a **`const`-constructed field** — the generator inserts it as a
component exactly like the data fields:

```dart
@Bundle()
final class PlayerBundle with _$PlayerBundle {
  // Tag: const-constructed, no data. Inserted as a component like any field.
  final Player player = const Player();

  // Data components.
  final Health health = Health(100);
  final Velocity velocity = Velocity(0, 0);

  // A flutter_scene node bound to this entity (see the integration section).
  final SceneNodeRef node = SceneNodeRef(Node(mesh: _mesh));

  static final Mesh _mesh = Mesh(SphereGeometry(radius: 0.5), UnlitMaterial());
}
```

That one bundle spawns an entity **tagged** `Player` that **carries** `Health`,
`Velocity`, and a `SceneNodeRef`. When a field needs constructor arguments, give
the bundle a factory — see
[`PlayerBundle`](examples/scene_game/lib/player/bundles.dart) and
[`RockBundle`](examples/scene_game/lib/rocks/bundles.dart) for the real pattern.

### 5. Events — decoupled messages

Events let one feature announce something that **several unrelated features**
react to, without depending on each other. They are typed channels with
independent reader cursors — one system sends, many read, none steal from the
others. Register ownership in the owning plugin with `app.addEvent<EnemyKilled>()`
(§1).

```dart
final class Score {
  int value = 0;
}

/// Announced once when an enemy dies. It carries a *snapshot* of what readers
/// need, because the entity is despawned the same frame — readers must never
/// look the dead entity back up.
final class EnemyKilled {
  final Vector3 position;
  final int bounty;
  const EnemyKilled(this.position, this.bounty);
}

// The combat feature owns death: despawn the enemy and announce it once.
@System()
void resolveEnemyDeaths(
  @Query(requires: [Enemy]) Query2<Health, SceneTransform> enemies,
  Commands commands,
  EventWriter<EnemyKilled> killed,
) {
  enemies.each((entity, health, transform) {
    if (health.current > 0) return;
    killed.send(EnemyKilled(transform.translation.clone(), 10));
    commands.despawn(entity); // deferred; the enemy leaves the query next frame
  });
}

// A *different* feature reacts, with no reference to the combat code. Scoring,
// VFX, and audio each read the same event independently.
@System()
void awardBounty(EventReader<EnemyKilled> killed, @Resource() Score score) {
  killed.forEach((event) => score.value += event.bounty);
}
```

**Why an event and not a direct call?** Because combat shouldn't know about
scoring, particles, or sound. It announces *an enemy died here* once; each
feature decides what to do. A direct call would couple combat to every reactor —
exactly what events avoid. (For a single producer and a single consumer in the
same feature, skip the event and just call the code.)

### 6. Resources — shared state (and a save repo)

Resources are singleton objects stored in the world: input, score, config, the
physics world, a database handle. Systems resolve them once and receive the same
instance every run.

```dart
final class InputState {
  double horizontal = 0;
  bool firePressed = false;
}

@System()
void readInput(@Resource() InputState input) {
  if (input.firePressed) {
    // ...
  }
}
```

Each resource is owned by one place — the plugin that uses it, or a single
insertion through the `Game` for a dependency the Flutter widget also holds.
`insertResource` **fails loud** on a duplicate; use `replaceResource` to swap
intentionally. Game code can also reach the world directly with safe helpers:

```dart
// In the owning plugin:
app.insertResource<InputState>(InputState());

if (world.has<Health>(entity)) {
  world.get<Health>(entity).current -= 10;
}
final maybeInput = world.tryResource<InputState>();
```

**A save repo is just a resource.** Wrap your storage (SQLite, Hive, …) in a
resource that owns all disk access, inject it, and have systems call its methods.
Give persisted entities a stable id component — entity indices are **not** stable
across a reload, so cross-references must use your own id, not the raw index:

```dart
@ObjectComponent()
final class Persisted {
  final int id; // stable across saves; remap entity refs through this, not the index
  const Persisted(this.id);
}

final class SaveSignal {
  bool requested = false; // flipped by your save button or on a scene/mode change
}

/// The single owner of disk access, inserted as a resource.
final class SaveRepo {
  SaveRepo(this._db);
  final Database _db;

  /// Persist rows in one batched transaction. Called on an explicit save /
  /// checkpoint — never every frame, since SQLite writes block.
  void saveTransforms(List<(int id, SceneTransform transform)> rows) {
    _db.transaction((txn) {
      for (final (id, t) in rows) {
        txn.insert(
          'transforms',
          {'id': id, 'x': t.x, 'y': t.y, 'z': t.z},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

@System()
void saveGame(
  @Query() Query2<Persisted, SceneTransform> entities,
  @Resource() SaveRepo repo,
  @Resource() SaveSignal save,
) {
  if (!save.requested) return; // only on an explicit save / mode change
  save.requested = false;

  final rows = <(int, SceneTransform)>[];
  entities.each((entity, persisted, t) => rows.add((persisted.id, t)));
  repo.saveTransforms(rows); // one list alloc on a checkpoint is fine — not per frame
}
```

The repo is constructed once (with an open `Database`) and inserted through the
`Game` like any widget-shared resource. Saving on a checkpoint — an explicit save
or a scene/mode change — keeps the per-frame path free of blocking I/O. (If your
DB package is async, return the `Future` and `await` it off the frame loop; a
checkpoint can afford to.)

## Rendering: the `flutter_scene` integration

`scene_dash_flutter_scene` wraps the pure-Dart `App` in a scene-aware `Game` that:

- exposes the live `Scene` and `SceneCommands` as `@Resource()`s;
- **mounts** entity-bound `SceneNodeRef` nodes into the scene before `update`, so a
  queried node is already parented (no `parent == null` guards);
- **syncs** the optional `SceneTransform` component onto bound nodes each frame;
- exposes a `SceneNodeIndex` resource (node → entity) for **picking**.

You choose where transform authority lives:

- **ECS-owned** — add a `SceneTransform`; the integration writes it onto the node.
  Best for serialization, save files, networking, headless simulation.
- **Node-owned** — store only a `SceneNodeRef` and mutate the native node directly.
  Best for visual-only state `flutter_scene` already holds. Add `PhysicsDriven` so
  generic transform sync skips entities a physics body (or another authority) owns.

> **Access-metadata rule:** mutating an object reached *through* a component (a
> `Node` or a physics body behind `SceneNodeRef`) counts as **writing** that
> component. Declare `writes: [SceneNodeRef]` whenever a system changes the
> referenced node.

Picking resolves a hit `Node` back to its entity:

```dart
@System()
void pick(
  @Resource() Scene scene,
  @Resource() SceneNodeIndex nodes,
  @Resource() PickRequest request, // your resource holding a ray to test
) {
  final hit = scene.raycast(request.ray);
  if (hit == null) return;
  final entity = nodes.entityOf(hit.node); // walks up to the bound ancestor
  if (entity != null) {
    // act on the entity
  }
}
```

See the **[integration guide](docs/integration.md)** for node mounting, transform
authority, scene commands, reaching native `flutter_scene` features, and hardware
instancing.

## Physics with Rapier

Scene-Dash does **not** implement physics. You attach a native `flutter_scene`
physics world (here `flutter_scene_rapier`) to the scene graph, then bridge that
same world into the ECS with `PhysicsPlugin`. The plugin inserts the world as a
`@Resource() PhysicsWorld` and registers a `CollisionEvent` ECS event.

**1. Create the world, attach it, add the plugin:**

```dart
final physics = RapierWorld(gravity: Vector3(0, -9.81, 0));
final scene = Scene()..root.addComponent(physics); // physics lives on the scene graph

final game = Game(scene: scene)
  ..addPlugin(PhysicsPlugin(physics)) // ...and is bridged into the ECS as @Resource() PhysicsWorld
  ..addPlugin(const PlayerPlugin());
```

**2. Build bodies and colliders on the entity's node.** Physics objects live on
the `flutter_scene` node; the entity stores a `SceneNodeRef`, plus `PhysicsDriven`
when the physics body owns the transform:

```dart
@Bundle()
final class RockBundle with _$RockBundle {
  final Rock rock = const Rock();        // a @Tag
  final PhysicsDriven physics = const PhysicsDriven(); // physics owns the transform
  final SceneNodeRef node;

  RockBundle({required double x})
      : node = SceneNodeRef(
          Node(
            mesh: Mesh(SphereGeometry(radius: 0.5), UnlitMaterial()),
            localTransform: Matrix4.translation(Vector3(x, 10, 0)),
          )
            ..addComponent(RapierRigidBody(type: BodyType.dynamic_))
            ..addComponent(
              RapierCollider(
                shape: SphereShape(radius: 0.5),
                collisionLayer: PhysicsLayers.rock,
              ),
            ),
        );
}
```

**3. Query the `PhysicsWorld` resource** for immediate scene queries — raycasts,
overlap checks, ground probes. This `fixedPrePhysics` system steers the player
through its native character controller, probing the ground to decide whether to
fall. It reaches the controller through the `SceneNodeRef`, so it declares
`writes: [SceneNodeRef]`:

```dart
@System()
void movePlayerBody(
  @Query(requires: [Player], writes: [SceneNodeRef]) Single<SceneNodeRef> player,
  @Resource() InputState input,
  @Resource() FixedTime time,
  @Resource() PhysicsWorld physics,
) {
  final ref = player.value;
  final controller = ref.component<RapierKinematicCharacterController>();
  if (controller == null) return;

  // Probe straight down: is there ground within reach?
  final origin = ref.node.globalTransform.getTranslation();
  final grounded = physics.raycast(
        Ray.originDirection(origin, Vector3(0, -1, 0)),
        maxDistance: 1.1,
        layerMask: PhysicsLayers.world,
      ) !=
      null;

  final dt = time.delta;
  final motion = Vector3(input.horizontal * 4.0 * dt, 0, 0);
  if (!grounded) motion.y = -9.81 * dt; // fall when nothing is underfoot
  controller.move(motion);              // native move-and-slide
}
```

**4. Read collisions as an ECS event.** The plugin drains the native collision
stream at `frameStart` and republishes it as `CollisionEvent`:

```dart
@System()
void readCollisions(EventReader<CollisionEvent> collisions) {
  collisions.forEach((collision) {
    // translate raw backend collision data into your own game events
  });
}
```

For larger games, treat raw collisions as a boundary: keep gameplay meaning
(teams, hitboxes, damage) in your own components and events, and translate physics
events into them. That keeps the backend swappable. The full physics walkthrough —
`BasicPhysicsWorld` vs. a Rapier backend, layers/masks, triggers, and the event
bridge — is in the **[integration guide](docs/integration.md#physics-and-collisions)**.

## Packages and Examples

| Path | Purpose |
| --- | --- |
| [`packages/scene_dash`](packages/scene_dash) | Pure-Dart ECS runtime: annotations, commands, resources, events, schedules, queries. |
| [`packages/scene_dash_generator`](packages/scene_dash_generator) | `source_gen` / `build_runner` adapters for systems, bundles, and plugin metadata. |
| [`packages/scene_dash_flutter_scene`](packages/scene_dash_flutter_scene) | `Game`, `SceneNodeRef`, `SceneCommands`, `SceneTransform`, `PhysicsPlugin`, and the scene frame integration. |
| [`examples/headless_example`](examples/headless_example) | Headless generated ECS example (no Flutter). |
| [`examples/scene_game`](examples/scene_game) | Complete `flutter_scene` + Rapier game driven by Scene-Dash. |
| [`benchmarks`](benchmarks) | Pure-Dart query and structural benchmarks. |

Deeper docs: the [architecture and rationale](docs/concept.md) and the
[`flutter_scene` integration guide](docs/integration.md).

## Verification

Useful checks while developing:

```bash
flutter pub get
dart analyze packages/scene_dash
flutter analyze packages/scene_dash_flutter_scene
```

Package-specific tests:

```bash
cd packages/scene_dash
dart test

cd ../scene_dash_flutter_scene
flutter test
```

The `flutter_scene` integration imports `package:flutter_scene/scene.dart` for the
0.18.x API.
