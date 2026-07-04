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

}

final unitSettingsProvider =
    AsyncNotifierProvider<UnitSettingsNotifier, UnitSettings>(
  UnitSettingsNotifier.new,
);
