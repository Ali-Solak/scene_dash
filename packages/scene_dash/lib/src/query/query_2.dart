import '../entity/entity.dart';
import '../storage/component_store.dart';
import '../storage/object_store.dart';
import '../world/world.dart';
import 'query.dart';

/// Callback invoked once per matching entity for a two-component query.
typedef Query2Callback<A, B> = void Function(Entity entity, A a, B b);

/// A cached query over two object components [A] and [B], with optional
/// `with`/`without` filters.
final class Query2<A, B> extends Query {
  final World _world;
  final ObjectComponentStore<A> _a;
  final ObjectComponentStore<B> _b;
  final List<ComponentStore> _withStores;
  final List<ComponentStore> _withoutStores;

  late final List<ComponentStore> _driverCandidates = <ComponentStore>[
    _a,
    _b,
    ..._withStores,
  ];

  Query2(
    this._world,
    this._a,
    this._b,
    this._withStores,
    this._withoutStores,
  );

  /// Invokes [callback] for every live entity that has both [A] and [B] and
  /// satisfies the filters.
  void each(Query2Callback<A, B> callback) {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    final driverIsB = identical(driver, _b);
    _world.beginQuery();
    try {
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);

        final aDense = driverIsA ? i : _a.denseIndexOf(entityIndex);
        if (aDense < 0) continue;

        final bDense = driverIsB ? i : _b.denseIndexOf(entityIndex);
        if (bDense < 0) continue;

        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }

        callback(
          _world.entities.resolve(entityIndex),
          _a.valueAt(aDense),
          _b.valueAt(bDense),
        );
      }
    } finally {
      _world.endQuery();
    }
  }

  /// Whether no live entity matches this query. Stops at the first match;
  /// allocation-free.
  bool get isEmpty {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    final driverIsB = identical(driver, _b);
    _world.beginQuery();
    try {
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);
        if ((driverIsA ? i : _a.denseIndexOf(entityIndex)) < 0) continue;
        if ((driverIsB ? i : _b.denseIndexOf(entityIndex)) < 0) continue;
        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }
        return false;
      }
      return true;
    } finally {
      _world.endQuery();
    }
  }

  /// Resolves the single matching entity as `(entity, a, b)`, or `null` when
  /// none match. Throws [StateError] when more than one entity matches. See
  /// `Query1.singleOrNull` for allocation notes.
  (Entity, A, B)? singleOrNull() {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    final driverIsB = identical(driver, _b);
    _world.beginQuery();
    try {
      (Entity, A, B)? match;
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);
        final aDense = driverIsA ? i : _a.denseIndexOf(entityIndex);
        if (aDense < 0) continue;
        final bDense = driverIsB ? i : _b.denseIndexOf(entityIndex);
        if (bDense < 0) continue;
        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }
        if (match != null) {
          throw StateError(
            'Query2<$A, $B>.single: expected exactly one matching entity, '
            'found more than one.',
          );
        }
        match = (
          _world.entities.resolve(entityIndex),
          _a.valueAt(aDense),
          _b.valueAt(bDense),
        );
      }
      return match;
    } finally {
      _world.endQuery();
    }
  }

  /// Resolves the single matching entity as `(entity, a, b)`. Throws
  /// [StateError] when zero or more than one entity matches.
  (Entity, A, B) single() {
    final match = singleOrNull();
    if (match == null) {
      throw StateError(
        'Query2<$A, $B>.single: expected exactly one matching entity, found '
        'none.',
      );
    }
    return match;
  }
}
