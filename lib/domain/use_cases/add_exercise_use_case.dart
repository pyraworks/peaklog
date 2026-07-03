import '../../core/database/database_helper.dart';
import '../../core/models/exercise.dart';
import '../../core/utils/normalize.dart';
import '../../data/repositories/exercise_repository_impl.dart';

class AddExerciseUseCase {
  static Future<Exercise?> execute({
    required String displayName,
    String? categoryId,
    BestType? bestType,
    String baseUnit = 'kg',
    bool pbHigherIsBetter = true,
    ExerciseType exerciseType = ExerciseType.record,
    int currentCount = 0,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return null;

    final normalized = normalize(trimmed);

    // The partial UNIQUE index on normalized_name (WHERE is_archived = 0)
    // allows a new active exercise to coexist with an archived one of the same
    // name. Manual creation must NEVER unarchive — only the Health import path
    // may do that. Return early only when an active exercise already exists.
    final existing = await DatabaseHelper.instance
        .findExerciseByNormalizedName(normalized);

    if (existing != null && !existing.isArchived) {
      return existing;
    }
    final exercise = Exercise.create(
      displayName: trimmed,
      categoryId: categoryId,
      bestType: bestType,
      baseUnit: baseUnit,
      pbHigherIsBetter: pbHigherIsBetter,
      exerciseType: exerciseType,
      orderIndex: currentCount,
    );
    return ExerciseRepositoryImpl.instance.insert(exercise);
  }
}
