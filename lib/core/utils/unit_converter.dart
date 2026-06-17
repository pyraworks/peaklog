class UnitConverter {
  static const double _kgToLbs = 2.20462;
  static const double _kmToMi = 0.621371;

  static double kgToLbs(double kg) => kg * _kgToLbs;
  static double lbsToKg(double lbs) => lbs / _kgToLbs;
  static double kmToMi(double km) => km * _kmToMi;
  static double miToKm(double mi) => mi / _kmToMi;

  static String secondsToDisplay(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }

  static int displayToSeconds(String display) {
    final parts = display.split(':');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60 +
          (int.tryParse(parts[2]) ?? 0);
    }
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    }
    return int.tryParse(display) ?? 0;
  }

  static String formatWeight(double kg, String unit) {
    final value = unit == 'lbs' ? kgToLbs(kg) : kg;
    return '${_fmt(value)} $unit';
  }

  static String formatDistance(double km, String unit) {
    final value = unit == 'mi' ? kmToMi(km) : km;
    return '${_fmt(value)} $unit';
  }

  static String formatEtc(double value, String unit) =>
      unit.isEmpty ? _fmt(value) : '${_fmt(value)} $unit';

  static String _fmt(double value) {
    final s = value.toStringAsFixed(1);
    return s.endsWith('.0') ? value.toStringAsFixed(0) : s;
  }
}
