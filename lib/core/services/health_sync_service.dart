import 'package:health/health.dart';
import '../models/health_workout.dart';

class HealthSyncService {
  final _health = Health();

  Future<void> configure() => _health.configure();

  Future<bool> requestPermission() async {
    return _health.requestAuthorization([
      HealthDataType.WORKOUT,
      HealthDataType.DISTANCE_WALKING_RUNNING,
    ]);
  }

  /// 최근 90일 내 모든 Activity 가져오기 (중복 제거 없음 — 사용자가 직접 선택).
  Future<List<HealthWorkout>> fetchRecentActivities() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: [HealthDataType.WORKOUT],
    );

    final workouts = <HealthWorkout>[];

    for (final dp in dataPoints) {
      if (dp.value is! WorkoutHealthValue) continue;
      final workout = dp.value as WorkoutHealthValue;

      final activityType = _mapActivityType(workout.workoutActivityType);
      final durationSec = dp.dateTo.difference(dp.dateFrom).inSeconds;
      if (durationSec <= 0) continue;

      final distM = workout.totalDistance ?? 0;

      workouts.add(HealthWorkout(
        workoutId: dp.uuid,
        startTime: dp.dateFrom,
        durationSeconds: durationSec,
        distanceKm: distM / 1000,
        activityType: activityType,
      ));
    }

    workouts.sort((a, b) => b.startTime.compareTo(a.startTime));
    return workouts;
  }

  static HealthActivityType _mapActivityType(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.RUNNING:
        return HealthActivityType.running;
      case HealthWorkoutActivityType.BIKING:
      case HealthWorkoutActivityType.BIKING_STATIONARY:
      case HealthWorkoutActivityType.HAND_CYCLING:
        return HealthActivityType.cycling;
      case HealthWorkoutActivityType.SWIMMING:
      case HealthWorkoutActivityType.SWIMMING_OPEN_WATER:
      case HealthWorkoutActivityType.SWIMMING_POOL:
        return HealthActivityType.swimming;
      default:
        return HealthActivityType.other;
    }
  }
}

final healthSyncService = HealthSyncService();
