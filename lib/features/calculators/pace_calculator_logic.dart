class PaceCalculatorLogic {
  static const double halfMarathonKm = 21.0975;
  static const double marathonKm = 42.195;

  static double? paceSecondsPerKm({
    required double distanceKm,
    required int totalSeconds,
  }) {
    if (distanceKm <= 0 || totalSeconds <= 0) return null;
    return totalSeconds / distanceKm;
  }

  static int? totalSeconds({
    required double distanceKm,
    required double paceSecondsPerKm,
  }) {
    if (distanceKm <= 0 || paceSecondsPerKm <= 0) return null;
    return (distanceKm * paceSecondsPerKm).round();
  }

  // Formats seconds-per-km as "M:SS" — no leading zero on minutes.
  static String formatPace(double secondsPerKm) {
    final total = secondsPerKm.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // Formats total seconds as "M:SS" or "H:MM:SS" — no leading zero on first unit.
  static String formatTime(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
    return '$m:$ss';
  }

  // Parses "M:SS" or "H:MM:SS" → total seconds. Returns null on invalid input.
  static int? parseTimeOrPace(String text) {
    final parts = text.trim().split(':');
    if (parts.length == 2) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      if (a == null || b == null || b < 0 || b >= 60) return null;
      return a * 60 + b;
    }
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h == null || m == null || s == null) return null;
      if (m < 0 || m >= 60 || s < 0 || s >= 60) return null;
      return h * 3600 + m * 60 + s;
    }
    return null;
  }

  // Returns [(label, cumulativeSeconds)].
  // < 1km: 100m increments until finish.
  // >= 1km: km increments only — no sub-km splits.
  static List<(String, int)> generateSplits(
    double distanceKm,
    double paceSecPerKm,
  ) {
    if (distanceKm <= 0 || paceSecPerKm <= 0) return [];
    final result = <(String, int)>[];

    if (distanceKm <= 1.0) {
      for (int i = 1; i * 0.1 <= distanceKm + 1e-9; i++) {
        final d = i * 0.1;
        result.add(('${i * 100} m', (d * paceSecPerKm).round()));
      }
    } else {
      final fullKm = distanceKm.truncate();
      for (int km = 1; km <= fullKm; km++) {
        result.add(('$km km', (km.toDouble() * paceSecPerKm).round()));
      }
      final frac = distanceKm - fullKm;
      if (frac > 1e-6) {
        result.add((_finishLabel(distanceKm), (distanceKm * paceSecPerKm).round()));
      }
    }

    return result;
  }

  static String _finishLabel(double km) {
    if ((km - halfMarathonKm).abs() < 0.01) return '21.1 km Finish';
    if ((km - marathonKm).abs() < 0.01) return '42.195 km Finish';
    return '${km.toStringAsFixed(1)} km Finish';
  }
}
