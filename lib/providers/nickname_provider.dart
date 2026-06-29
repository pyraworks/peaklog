import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NicknameNotifier extends AsyncNotifier<String> {
  static const _key = 'nickname';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  Future<void> setNickname(String name) async {
    final trimmed = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
    state = AsyncData(trimmed);
  }
}

final nicknameProvider =
    AsyncNotifierProvider<NicknameNotifier, String>(NicknameNotifier.new);
