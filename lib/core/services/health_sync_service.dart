import 'package:health/health.dart';
import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../models/health_import.dart';
import '../models/record.dart';
import '../utils/unit_converter.dart';

class SyncResult {
  final int imported;
  final int skipped;
  final List<String> newPbs;

  const SyncResult({
    required this.imported,
    required this.skipped,
    required this.newPbs,
  });
}

class _Segment {
  final String displayName;
  final int distanceM;
  const _Segment(this.displayName, this.distanceM);
}

class HealthSyncService {
  static const _toleranceM = 50;

  static const _segments = [
    _Segment('1km Run', 1000),
    _Segment('5km Run', 5000),
    _Segment('10km Run', 10000),
    _Segment('Half Marathon', 21097),
    _Segment('Full Marathon', 42195),
  ];

  final _health = Health();

  Future<void> configure() => _health.configure();

  Future<bool> requestPermission() async {
    return _health.requestAuthorization([HealthDataType.WORKOUT]);
  }

  Future<SyncResult> syncRunningWorkouts() async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: [HealthDataType.WORKOUT],
    );

    int imported = 0;
    int skipped = 0;
    final newPbs = <String>[];

    for (final dp in dataPoints) {
      if (dp.value is! WorkoutHealthValue) continue;
      final workout = dp.value as WorkoutHealthValue;

      if (workout.workoutActivityType !=
          HealthWorkoutActivityType.RUNNING) continue;

      final distM = workout.totalDistance;
      if (distM == null || distM <= 0) continue;

      final durationSec = dp.dateTo.difference(dp.dateFrom).inSeconds;
      if (durationSec <= 0) continue;

      // Match to a target segment (±50m)
      _Segment? matched;
      for (final seg in _segments) {
        if ((distM - seg.distanceM).abs() <= _toleranceM) {
          matched = seg;
          break;
        }
      }
      if (matched == null) continue;

      // Deduplication hash
      final startSec = dp.dateFrom.millisecondsSinceEpoch ~/ 1000;
      final hash = '${distM}_${durationSec}_$startSec';

      if (await db.hasHealthImport(hash)) {
        skipped++;
        continue;
      }

      // Find or create running exercise
      final exercise =
          await _findOrCreateRunningExercise(db, matched.displayName);

      // Check previous best before insert
      final prevBestSec =
          await db.getBestDurationForExercise(exercise.id);

      // Create record
      final record = Record.create(
        exerciseId: exercise.id,
        performedAt: dp.dateFrom.millisecondsSinceEpoch,
        distance: distM / 1000,
        durationSeconds: durationSec,
      );
      await db.insertRecord(record);

      // Log import for deduplication
      await db.insertHealthImport(HealthImport(
        id: hash,
        recordId: record.id,
        importedAt: now.millisecondsSinceEpoch,
      ));

      // PB detection
      if (prevBestSec == null || durationSec < prevBestSec) {
        newPbs.add(
          '${matched.displayName}  ${UnitConverter.secondsToDisplay(durationSec)}',
        );
      }

      imported++;
    }

    return SyncResult(
        imported: imported, skipped: skipped, newPbs: newPbs);
  }

  Future<Exercise> _findOrCreateRunningExercise(
      DatabaseHelper db, String displayName) async {
    final exercises = await db.getExercises();
    final normalized = normalizeExerciseName(displayName);
    final existing =
        exercises.where((e) => e.normalizedName == normalized).firstOrNull;
    if (existing != null) return existing;

    final exercise = Exercise.create(
      displayName: displayName,
      category: ExerciseCategory.running,
      orderIndex: exercises.length,
    );
    await db.insertExercise(exercise);
    return exercise;
  }
}

final healthSyncService = HealthSyncService();
