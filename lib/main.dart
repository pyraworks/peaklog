import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app.dart';
import 'core/services/analytics_service.dart';
import 'firebase_options.dart';
import 'providers/analytics_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AnalyticsService analytics = const AnalyticsService();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
    overrides: [analyticsProvider.overrideWithValue(analytics)],
    child: const PeakLogApp(),
  ));
}
