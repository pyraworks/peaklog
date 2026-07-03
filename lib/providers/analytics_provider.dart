import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/analytics_service.dart';

// Overridden in main.dart after Firebase initialization.
// Falls back to a no-op AnalyticsService if Firebase is unavailable.
final analyticsProvider = Provider<AnalyticsService>((ref) {
  return const AnalyticsService();
});
