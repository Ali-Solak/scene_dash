import '../schedule/schedule_label.dart';
import '../schedule/system_label.dart';

/// A reusable timing record for a single system, accumulated across frames.
///
/// One [SystemTiming] is created per system the first time it runs under
/// profiling and then updated in place — the profiler never allocates a fresh
/// record per frame. Durations are stored as microsecond integers (no [Duration]
/// allocation on the hot path) and exposed through [Duration] getters for
/// display.
final class SystemTiming {
  SystemTiming({
    required this.label,
    required this.debugName,
    required this.schedule,
  });

  /// The system's stable identity.
  final SystemLabel label;

  /// A short human-readable name for diagnostics (the declared system name).
  final String debugName;

  /// The schedule this system runs in.
  final ScheduleLabel schedule;

  /// Number of times the system has run.
  int runs = 0;

  /// Total time spent in the system, in microseconds.
  int totalMicros = 0;

  /// Time spent in the most recent run, in microseconds.
  int latestMicros = 0;

  /// The slowest single run observed, in microseconds.
  int maxMicros = 0;

  /// The frame number of the most recent run (-1 until first run).
  int lastFrame = -1;

  /// Total time spent in the system.
  Duration get total => Duration(microseconds: totalMicros);

  /// Time spent in the most recent run.
  Duration get latest => Duration(microseconds: latestMicros);

  /// The slowest single run observed.
  Duration get maximum => Duration(microseconds: maxMicros);

  /// Mean time per run (zero before the first run).
  Duration get average =>
      runs == 0 ? Duration.zero : Duration(microseconds: totalMicros ~/ runs);

  @override
  String toString() {
    final ms = (latestMicros / 1000).toStringAsFixed(2);
    return '$debugName  $ms ms';
  }
}
