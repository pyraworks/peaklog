import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/enums/best_type.dart';

const defaultBestTypePrefsKey = 'default_best_type';

BestType parseDefaultBestType(String? raw) => BestType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => BestType.pr,
    );

/// User-editable preference, read/written from the Settings screen. Only
/// changes which segment is preselected when creating a new exercise — it
/// never touches an existing exercise's stored bestType.
class DefaultBestTypeNotifier extends AsyncNotifier<BestType> {
  @override
  Future<BestType> build() async {
    final prefs = await SharedPreferences.getInstance();
    return parseDefaultBestType(prefs.getString(defaultBestTypePrefsKey));
  }

  Future<void> setDefaultBestType(BestType value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(defaultBestTypePrefsKey, value.name);
    state = AsyncData(value);
  }
}

final defaultBestTypeProvider =
    AsyncNotifierProvider<DefaultBestTypeNotifier, BestType>(
  DefaultBestTypeNotifier.new,
);
