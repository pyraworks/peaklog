import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/exercise.dart';

class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async {
    return DatabaseHelper.instance.getExercises();
  }

  Future<void> addExercise(String name, ExerciseType type) async {
    final current = state.valueOrNull ?? [];
    if (current.length >= 6) return;
    final exercise = Exercise(
      name: name,
      type: type,
      orderIndex: current.length,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final id = await DatabaseHelper.instance.insertExercise(exercise);
    state = AsyncData([...current, exercise.copyWith(id: id)]);
  }

  Future<void> renameExercise(int id, String name) async {
    await DatabaseHelper.instance.updateExerciseName(id, name);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((e) => e.id == id ? e.copyWith(name: name) : e).toList(),
    );
  }

  Future<void> deleteExercise(int id) async {
    await DatabaseHelper.instance.deleteExercise(id);
    final current = state.valueOrNull ?? [];
    final updated = current.where((e) => e.id != id).toList();
    final reindexed = updated
        .asMap()
        .entries
        .map((e) => e.value.copyWith(orderIndex: e.key))
        .toList();
    state = AsyncData(reindexed);
  }
}

final exercisesProvider =
    AsyncNotifierProvider<ExercisesNotifier, List<Exercise>>(
  ExercisesNotifier.new,
);
