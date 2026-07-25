import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/analytics_service.dart';
import 'providers/analytics_provider.dart';
import 'providers/launch_screen_provider.dart';

Future<void> bootstrap({required FirebaseOptions firebaseOptions}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final launchScreen = parseLaunchScreen(prefs.getString(launchScreenPrefsKey));

  AnalyticsService analytics = const AnalyticsService();

  try {
    await Firebase.initializeApp(options: firebaseOptions);
    analytics = AnalyticsService(FirebaseAnalytics.instance);

    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  } catch (_) {
    // Firebase unavailable — app continues with no-op analytics.
  }

  unawaited(analytics.logAppOpen());

  runApp(ProviderScope(
    overrides: [
      analyticsProvider.overrideWithValue(analytics),
      resolvedLaunchScreenProvider.overrideWithValue(launchScreen),
    ],
    child: const PeakLogApp(),
  ));
}
