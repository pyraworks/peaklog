import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorPrefs {
  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  // ── Last screen ──────────────────────────────────────────────────────────────
  static Future<String> getLastScreen() async =>
      (await _p).getString('calc_last_screen') ?? '';
  static Future<void> setLastScreen(String v) async =>
      (await _p).setString('calc_last_screen', v);

  // ── 1RM ──────────────────────────────────────────────────────────────────────
  static Future<double> get1rmWeight() async =>
      (await _p).getDouble('calc_1rm_weight') ?? 100.0;
  static Future<void> set1rmWeight(double v) async =>
      (await _p).setDouble('calc_1rm_weight', v);
  static Future<String> get1rmUnit() async =>
      (await _p).getString('calc_1rm_unit') ?? 'kg';
  static Future<void> set1rmUnit(String v) async =>
      (await _p).setString('calc_1rm_unit', v);

  // ── Pace ─────────────────────────────────────────────────────────────────────
  static Future<String> getPacePreset() async =>
      (await _p).getString('calc_pace_preset') ?? '5 km';
  static Future<void> setPacePreset(String v) async =>
      (await _p).setString('calc_pace_preset', v);
  static Future<double> getPaceDistanceKm() async =>
      (await _p).getDouble('calc_pace_dist_km') ?? 5.0;
  static Future<void> setPaceDistanceKm(double v) async =>
      (await _p).setDouble('calc_pace_dist_km', v);
  static Future<String> getPaceTimeText() async =>
      (await _p).getString('calc_pace_time') ?? '';
  static Future<void> setPaceTimeText(String v) async =>
      (await _p).setString('calc_pace_time', v);
  static Future<String> getPacePaceText() async =>
      (await _p).getString('calc_pace_pace') ?? '';
  static Future<void> setPacePaceText(String v) async =>
      (await _p).setString('calc_pace_pace', v);
  static Future<String> getPaceLastEdited() async =>
      (await _p).getString('calc_pace_last_edited') ?? '';
  static Future<void> setPaceLastEdited(String v) async =>
      (await _p).setString('calc_pace_last_edited', v);

  // ── Plate ─────────────────────────────────────────────────────────────────────
  static Future<String> getPlateUnit() async =>
      (await _p).getString('calc_plate_unit') ?? 'kg';
  static Future<void> setPlateUnit(String v) async =>
      (await _p).setString('calc_plate_unit', v);
  static Future<double> getPlateBarWeight() async =>
      (await _p).getDouble('calc_plate_bar') ?? 20.0;
  static Future<void> setPlateBarWeight(double v) async =>
      (await _p).setDouble('calc_plate_bar', v);
  static Future<double> getPlateTotalWeight() async =>
      (await _p).getDouble('calc_plate_total') ?? 60.0;
  static Future<void> setPlateTotalWeight(double v) async =>
      (await _p).setDouble('calc_plate_total', v);
  static Future<Map<double, int>> getPlateCounts(String unit) async {
    final raw = (await _p).getString('calc_plate_counts_$unit') ?? '{}';
    return _decodeCounts(raw);
  }

  static Future<void> setPlateCounts(String unit, Map<double, int> counts) async =>
      (await _p).setString('calc_plate_counts_$unit', _encodeCounts(counts));

  static Map<double, int> _decodeCounts(String json) {
    try {
      final raw = jsonDecode(json) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(double.parse(k), (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static String _encodeCounts(Map<double, int> counts) =>
      jsonEncode(counts.map((k, v) => MapEntry(k.toString(), v)));
}
