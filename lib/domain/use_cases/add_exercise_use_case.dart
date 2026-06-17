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
    int currentCount = 0,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return null;

    final normalized = normalize(trimmed);

    // insertExercise uses ConflictAlgorithm.ignore, which silently drops the
    // row when an archived exercise with the same normalized_name already
    // occupies the UNIQUE INDEX.  The caller would get back a UUID that has no
    // matching DB row, causing insertRecord to throw "exercise not found."
    // Fix: detect that case before creating and unarchive the old exercise
    // instead of creating a phantom new one.
    final existing = await DatabaseHelper.instance
        .findExerciseByNormalizedName(normalized);

    if (existing != null && existing.isArchived) {
      await DatabaseHelper.instance.unarchiveExercise(existing.id);
      return existing.copyWith(isArchived: false);
    }
    if (existing != null) {
      // An active exercise with the same normalized name already exists.
      // Return it directly — creating a new one would generate a phantom UUID
      // that insertExercise silently drops (ConflictAlgorithm.ignore + UNIQUE
      // constraint on normalized_name), causing insertRecord to throw
      // "exercise not found in DB".
      return existing;
    }
    final exercise = Exercise.create(
      displayName: trimmed,
      categoryId: categoryId,
      bestType: bestType,
      baseUnit: baseUnit,
      orderIndex: currentCount,
    );
    return ExerciseRepositoryImpl.instance.insert(exercise);
  }
}
