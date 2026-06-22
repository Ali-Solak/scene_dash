import '../entity/entity.dart';
import 'query_1.dart';

/// A system parameter that resolves to the one entity matching a single-component
/// query.
///
/// Use it instead of iterating a `Query1` whose match set is known to be exactly
/// one entity (a player, a camera rig, the level controller). It removes the
/// "pull one entity out of a bulk loop" boilerplate:
///
/// ```dart
/// void run(
///   @Query(requires: [Player, Mounted]) Single<SceneNodeRef> player,
/// ) {
///   final node = player.value.node;
/// }
/// ```
///
/// Resolution happens on access and is validated: it throws a descriptive
/// [StateError] when zero or more than one entity matches. For the "zero is
/// allowed" case use [OptionalSingle]. Resolution walks the query each access,
/// so this is intended for singletons, not hot per-entity loops.
final class Single<A> {
  /// Wraps [query]; normally constructed by the generated system adapter.
  Single(this._query);

  final Query1<A> _query;

  /// The matching component value. Throws [StateError] unless exactly one entity
  /// matches.
  A get value => _query.single().$2;

  /// The matching entity. Throws [StateError] unless exactly one entity matches.
  Entity get entity => _query.single().$1;
}

/// A system parameter that resolves to at most one entity matching a
/// single-component query.
///
/// Like [Single], but tolerates zero matches ([valueOrNull] returns `null`). It
/// still throws when more than one entity matches, so it never silently hides an
/// unexpected duplicate.
final class OptionalSingle<A> {
  /// Wraps [query]; normally constructed by the generated system adapter.
  OptionalSingle(this._query);

  final Query1<A> _query;

  /// Whether any entity matches the query.
  bool get isPresent => !_query.isEmpty;

  /// The matching component value, or `null` when none match. Throws
  /// [StateError] when more than one entity matches.
  A? get valueOrNull => _query.singleOrNull()?.$2;

  /// The matching entity, or `null` when none match. Throws [StateError] when
  /// more than one entity matches.
  Entity? get entityOrNull => _query.singleOrNull()?.$1;
}
