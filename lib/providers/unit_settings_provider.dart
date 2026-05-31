import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnitSettings {
  final String weightUnit;
  final String distanceUnit;

  const UnitSettings({this.weightUnit = 'kg', this.distanceUnit = 'km'});

  UnitSettings copyWith({String? weightUnit, String? distanceUnit}) => UnitSettings(
        weightUnit: weightUnit ?? this.weightUnit,
        distanceUnit: distanceUnit ?? this.distanceUnit,
      );
}

class UnitSettingsNotifier extends AsyncNotifier<UnitSettings> {
  @override
  Future<UnitSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return UnitSettings(
      weightUnit: prefs.getString('weightUnit') ?? 'kg',
      distanceUnit: prefs.getString('distanceUnit') ?? 'km',
    );
  }

  Future<void> toggleWeightUnit() async {
    final current = state.valueOrNull ?? const UnitSettings();
    final next = current.weightUnit == 'kg' ? 'lbs' : 'kg';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weightUnit', next);
    state = AsyncData(current.copyWith(weightUnit: next));
  }

  Future<void> toggleDistanceUnit() async {
    final current = state.valueOrNull ?? const UnitSettings();
    final next = current.distanceUnit == 'km' ? 'mi' : 'km';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('distanceUnit', next);
    state = AsyncData(current.copyWith(distanceUnit: next));
  }
}

final unitSettingsProvider =
    AsyncNotifierProvider<UnitSettingsNotifier, UnitSettings>(
  UnitSettingsNotifier.new,
);
