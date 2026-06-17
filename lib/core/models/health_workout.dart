enum HealthActivityType { running, cycling, swimming, other }

/// Ephemeral model — not persisted to DB.
/// Represents a single workout fetched from HealthKit.
class HealthWorkout {
  final String workoutId;      // HealthKit HKObject UUID
  final DateTime startTime;
  final int durationSeconds;
  final double distanceKm;
  final HealthActivityType activityType;

  const HealthWorkout({
    required this.workoutId,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceKm,
    this.activityType = HealthActivityType.running,
  });
}
