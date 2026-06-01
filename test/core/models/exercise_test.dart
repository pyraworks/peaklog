import 'package:flutter_test/flutter_test.dart';
import 'package:pbpr/core/models/exercise.dart';

void main() {
  test('Exercise.create sets id, normalizedName, timestamps', () {
    final e = Exercise.create(
      displayName: 'Back Squat',
      category: ExerciseCategory.strength,
      orderIndex: 0,
    );
    expect(e.id.isNotEmpty, isTrue);
    expect(e.normalizedName, 'back_squat');
    expect(e.category, ExerciseCategory.strength);
    expect(e.isArchived, isFalse);
  });

  test('toMap/fromMap round-trips correctly', () {
    final e = Exercise.create(
      displayName: 'Deadlift',
      category: ExerciseCategory.strength,
      orderIndex: 1,
    );
    final restored = Exercise.fromMap(e.toMap());
    expect(restored.id, e.id);
    expect(restored.displayName, 'Deadlift');
    expect(restored.normalizedName, 'deadlift');
    expect(restored.category, ExerciseCategory.strength);
    expect(restored.orderIndex, 1);
  });

  test('copyWith replaces specified fields', () {
    final e = Exercise.create(
      displayName: 'Squat',
      category: ExerciseCategory.strength,
      orderIndex: 0,
    );
    final updated = e.copyWith(displayName: 'Front Squat', orderIndex: 2);
    expect(updated.displayName, 'Front Squat');
    expect(updated.orderIndex, 2);
    expect(updated.id, e.id);
  });

  test('normalizeExerciseName handles spaces and special chars', () {
    expect(normalizeExerciseName('Back Squat'), 'back_squat');
    expect(normalizeExerciseName('5km Run!'), '5km_run');
    expect(normalizeExerciseName('  Fran  '), 'fran');
  });
}
