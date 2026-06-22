import '../entity/entity.dart';
import '../storage/component_store.dart';
import '../storage/object_store.dart';
import '../world/world.dart';
import 'query.dart';

/// Callback invoked once per matching entity for a three-component query.
typedef Query3Callback<A, B, C> = void Function(
  Entity entity,
  A a,
  B b,
  C c,
);

/// A cached query over three object components [A], [B] and [C], with optional
/// `requires`/`excludes` filters.
final class Query3<A, B, C> extends Query {
  final World _world;
  final ObjectComponentStore<A> _a;
  final ObjectComponentStore<B> _b;
  final ObjectComponentStore<C> _c;
  final List<ComponentStore> _withStores;
  final List<ComponentStore> _withoutStores;

  late final List<ComponentStore> _driverCandidates = <ComponentStore>[
    _a,
    _b,
    _c,
    ..._withStores,
  ];

  Query3(
    this._world,
    this._a,
    this._b,
    this._c,
    this._withStores,
    this._withoutStores,
  );

  /// Invokes [callback] for every live entity that has [A], [B] and [C] and
  /// satisfies the filters.
  void each(Query3Callback<A, B, C> callback) {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    final driverIsB = identical(driver, _b);
    final driverIsC = identical(driver, _c);
    _world.beginQuery();
    try {
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);

        final aDense = driverIsA ? i : _a.denseIndexOf(entityIndex);
        if (aDense < 0) continue;

        final bDense = driverIsB ? i : _b.denseIndexOf(entityIndex);
        if (bDense < 0) continue;

        final cDense = driverIsC ? i : _c.denseIndexOf(entityIndex);
        if (cDense < 0) continue;

        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }

        callback(
          _world.entities.resolve(entityIndex),
          _a.valueAt(aDense),
          _b.valueAt(bDense),
          _c.valueAt(cDense),
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
    final driverIsC = identical(driver, _c);
    _world.beginQuery();
    try {
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);
        if ((driverIsA ? i : _a.denseIndexOf(entityIndex)) < 0) continue;
        if ((driverIsB ? i : _b.denseIndexOf(entityIndex)) < 0) continue;
        if ((driverIsC ? i : _c.denseIndexOf(entityIndex)) < 0) continue;
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

  /// Resolves the single matching entity as `(entity, a, b, c)`, or `null` when
  /// none match. Throws [StateError] when more than one entity matches.
  (Entity, A, B, C)? singleOrNull() {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    final driverIsB = identical(driver, _b);
    final driverIsC = identical(driver, _c);
    _world.beginQuery();
    try {
      (Entity, A, B, C)? match;
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);
        final aDense = driverIsA ? i : _a.denseIndexOf(entityIndex);
        if (aDense < 0) continue;
        final bDense = driverIsB ? i : _b.denseIndexOf(entityIndex);
        if (bDense < 0) continue;
        final cDense = driverIsC ? i : _c.denseIndexOf(entityIndex);
        if (cDense < 0) continue;
        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }
        if (match != null) {
          throw StateError(
            'Query3<$A, $B, $C>.single: expected exactly one matching entity, '
            'found more than one.',
          );
        }
        match = (
          _world.entities.resolve(entityIndex),
          _a.valueAt(aDense),
          _b.valueAt(bDense),
          _c.valueAt(cDense),
        );
      }
      return match;
    } finally {
      _world.endQuery();
    }
  }

  /// Resolves the single matching entity as `(entity, a, b, c)`. Throws
  /// [StateError] when zero or more than one entity matches.
  (Entity, A, B, C) single() {
    final match = singleOrNull();
    if (match == null) {
      throw StateError(
        'Query3<$A, $B, $C>.single: expected exactly one matching entity, '
        'found none.',
      );
    }
    return match;
  }
}
