class PlateCalculatorLogic {
  static const kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  static const lbPlates = [45.0, 35.0, 25.0, 15.0, 10.0, 5.0, 2.5];
  static const kgBars = [10.0, 15.0, 20.0];
  static const lbBars = [15.0, 35.0, 45.0];

  // Total weight = bar + sum(plateWeight × count) for all plates.
  // count=2 means 1 plate per side (symmetrical loading).
  static double computeTotal({
    required double barWeight,
    required Map<double, int> plateCounts,
  }) {
    var total = barWeight;
    for (final entry in plateCounts.entries) {
      total += entry.key * entry.value;
    }
    return total;
  }

  // Greedy minimum-plates solver.
  // Returns map of plateSize → total count (always even: 0, 2, 4, …).
  static Map<double, int> solvePlates({
    required double totalWeightTarget,
    required double barWeight,
    required List<double> plateSizes,
  }) {
    final counts = <double, int>{for (final p in plateSizes) p: 0};
    var remaining = totalWeightTarget - barWeight;

    if (remaining <= 0) return counts;

    // Each pair adds 2 × plateWeight to total (1 plate per side).
    for (final plate in plateSizes) {
      final pairs = (remaining / (plate * 2)).floor();
      if (pairs > 0) {
        counts[plate] = pairs * 2;
        remaining -= pairs * 2 * plate;
      }
    }

    return counts;
  }
}
