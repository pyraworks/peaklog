import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/exercise.dart';

enum CalendarEntryMethod { swipe, button }

class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  const AnalyticsService([this._analytics]);

  Future<void> logAppOpen() async {
    try {
      await _analytics?.logAppOpen();
    } catch (_) {}
  }

  Future<void> logExerciseCreated({required ExerciseType exerciseType}) async {
    try {
      await _analytics?.logEvent(
        name: 'exercise_created',
        parameters: {'exercise_type': exerciseType.name},
      );
    } catch (_) {}
  }

  Future<void> logRecordSaved({required ExerciseType exerciseType}) async {
    try {
      await _analytics?.logEvent(
        name: 'record_saved',
        parameters: {'exercise_type': exerciseType.name},
      );
    } catch (_) {}
  }

  Future<void> logCalendarOpened({required CalendarEntryMethod entry}) async {
    try {
      await _analytics?.logEvent(
        name: 'calendar_opened',
        parameters: {'entry': entry.name},
      );
    } catch (_) {}
  }

  Future<void> logNoteCreated() async {
    try {
      await _analytics?.logEvent(name: 'note_created');
    } catch (_) {}
  }

  Future<void> logShareUsed() async {
    try {
      await _analytics?.logEvent(name: 'share_used');
    } catch (_) {}
  }
}
