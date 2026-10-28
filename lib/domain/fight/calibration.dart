/// Beats played during the timing calibration.
const calibrationBeats = 8;

/// Pulse of the calibration beats in ms (100 bpm).
const calibrationBeatMs = 600;

/// The player's usual delay in ms: the median distance of each tap to its
/// nearest beat. Taps further than [maxDistanceMs] from any beat are
/// ignored; returns `null` with fewer than [minTaps] usable taps.
int? calibrationOffset(
  List<int> beatsMs,
  List<int> tapsMs, {
  int maxDistanceMs = 250,
  int minTaps = 4,
}) {
  final offsets = <int>[];
  for (final tap in tapsMs) {
    int? nearest;
    for (final beat in beatsMs) {
      final offset = tap - beat;
      if (nearest == null || offset.abs() < nearest.abs()) nearest = offset;
    }
    if (nearest != null && nearest.abs() <= maxDistanceMs) {
      offsets.add(nearest);
    }
  }
  if (offsets.length < minTaps) return null;
  offsets.sort();
  final mid = offsets.length ~/ 2;
  return offsets.length.isOdd
      ? offsets[mid]
      : ((offsets[mid - 1] + offsets[mid]) / 2).round();
}
