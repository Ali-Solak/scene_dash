/// Marker base class for user-authored `@System` classes.
///
/// A `@System` class extends [GameSystem] and declares a synchronous `run(...)`
/// method whose parameters (queries, `Single`/`OptionalSingle`, resources,
/// commands, event readers and writers) are injected by a generated adapter.
///
/// The generator emits a public `$YourSystemAdapter` and a top-level
/// `SystemDescriptor` (e.g. `yourSystem`); game code registers the system by
/// passing that descriptor to `AppBuilder.addSystem`. There is no `with _$…`
/// mixin: a class system carries no wiring itself, so this base is just a marker
/// the generator recognizes.
abstract base class GameSystem {
  const GameSystem();
}
