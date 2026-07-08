import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LaunchScreen { home, calendar, calculatorHub }

const launchScreenPrefsKey = 'launch_screen';

LaunchScreen parseLaunchScreen(String? raw) => LaunchScreen.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => LaunchScreen.home,
    );

/// User-editable preference, read/written from the Settings screen.
/// Changing this does not affect the current session — see
/// [resolvedLaunchScreenProvider].
class LaunchScreenNotifier extends AsyncNotifier<LaunchScreen> {
  @override
  Future<LaunchScreen> build() async {
    final prefs = await SharedPreferences.getInstance();
    return parseLaunchScreen(prefs.getString(launchScreenPrefsKey));
  }

  Future<void> setLaunchScreen(LaunchScreen value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(launchScreenPrefsKey, value.name);
    state = AsyncData(value);
  }
}

final launchScreenProvider =
    AsyncNotifierProvider<LaunchScreenNotifier, LaunchScreen>(
  LaunchScreenNotifier.new,
);

/// The launch screen resolved once at process start (see main.dart) and
/// injected via ProviderScope override. HomePageView reads this — never
/// [launchScreenProvider] directly — so a preference change only takes
/// effect on the next cold start, not mid-session.
final resolvedLaunchScreenProvider =
    Provider<LaunchScreen>((ref) => LaunchScreen.home);
