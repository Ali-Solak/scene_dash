part of 'rocks.dart';

/// Spawn cadence plus RNG, injected as a resource.
final class RockSpawner {
  final math.Random random;
  double _accumulator = 0;

  RockSpawner({int? seed}) : random = math.Random(seed);

  /// Advances the timer; returns the number of rocks due this step.
  int tick(double dt) {
    _accumulator += dt;
    var due = 0;
    while (_accumulator >= rockSpawnInterval) {
      _accumulator -= rockSpawnInterval;
      due++;
    }
    return due;
  }

  /// A random X within the ramp's spawn band.
  double nextLane() => (random.nextDouble() * 2 - 1) * rockSpawnHalfWidth;

  bool nextIsFlaming() => random.nextDouble() < flamingRockChance;

  void reset() => _accumulator = 0;
}
