import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/exercise.dart';

class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async =>
      DatabaseHelper.instance.getExercises();

  Future<void> addExercise(String displayName, ExerciseCategory category) async {
    final current = state.valueOrNull ?? [];
    if (current.length >= 6) return;
    final exercise = Exercise.create(
      displayName: displayName,
      category: category,
      orderIndex: current.length,
    );
    await DatabaseHelper.instance.insertExercise(exercise);
    state = AsyncData([...current, exercise]);
  }

  Future<void> renameExercise(String id, String newName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = state.valueOrNull ?? [];
    final existing = current.firstWhere((e) => e.id == id);
    final updated = existing.copyWith(
      displayName: newName,
      normalizedName: normalizeExerciseName(newName),
      updatedAt: now,
    );
    await DatabaseHelper.instance.updateExercise(updated);
    state = AsyncData(current.map((e) => e.id == id ? updated : e).toList());
  }

  Future<void> deleteExercise(String id) async {
    await DatabaseHelper.instance.archiveExercise(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());
  }
}

final exercisesProvider =
    AsyncNotifierProvider<ExercisesNotifier, List<Exercise>>(
  ExercisesNotifier.new,
);
