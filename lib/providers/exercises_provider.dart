import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/exercise.dart';
import '../core/utils/normalize.dart';
import '../data/repositories/exercise_repository_impl.dart';
import '../domain/use_cases/add_exercise_use_case.dart';

class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async =>
      DatabaseHelper.instance.getExercises();

  Future<Exercise?> addExercise(
    String displayName, String? categoryId, {
    BestType? bestType,
    String baseUnit = 'kg',
    bool pbHigherIsBetter = true,
    ExerciseType exerciseType = ExerciseType.record,
  }) async {
    final current = state.valueOrNull ?? [];
    final exercise = await AddExerciseUseCase.execute(
      displayName: displayName,
      categoryId: categoryId,
      bestType: bestType,
      baseUnit: baseUnit,
      pbHigherIsBetter: pbHigherIsBetter,
      exerciseType: exerciseType,
      currentCount: current.length,
    );
    if (exercise == null) return null;
    state = AsyncData([
      ...current.where((e) => e.id != exercise.id),
      exercise,
    ]);
    return exercise;
  }

  Future<void> updateExerciseSettings(
    String id, {
    String? displayName,
    String? categoryId,
    BestType? bestType,
    String? baseUnit,
    int? timeCap,
    bool? pbHigherIsBetter,
  }) async {
    final current = state.valueOrNull ?? [];
    final existing = current.firstWhere((e) => e.id == id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final newName = displayName?.trim();
    var updated = existing.copyWith(
      displayName: (newName != null && newName.isNotEmpty)
          ? newName
          : existing.displayName,
      normalizedName: (newName != null && newName.isNotEmpty)
          ? normalize(newName)
          : existing.normalizedName,
      categoryId: categoryId ?? existing.categoryId,
      bestType: bestType ?? existing.bestType,
      baseUnit: baseUnit ?? existing.baseUnit,
      pbHigherIsBetter: pbHigherIsBetter ?? existing.pbHigherIsBetter,
      updatedAt: now,
    );
    if (timeCap != null) updated = updated.copyWith(timeCap: timeCap);
    await DatabaseHelper.instance.updateExercise(updated);
    state = AsyncData(current.map((e) => e.id == id ? updated : e).toList());
  }

  Future<void> setRecordType(String id, RecordType rt) async {
    await ExerciseRepositoryImpl.instance.updateRecordType(id, rt);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((e) => e.id == id ? e.copyWith(recordType: rt) : e).toList(),
    );
  }

  Future<void> renameExercise(String id, String newName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = state.valueOrNull ?? [];
    final existing = current.firstWhere((e) => e.id == id);
    final updated = existing.copyWith(
      displayName: newName,
      normalizedName: normalize(newName),
      updatedAt: now,
    );
    await DatabaseHelper.instance.updateExercise(updated);
    state = AsyncData(current.map((e) => e.id == id ? updated : e).toList());
  }

  Future<void> setPrBaseline(String id) async {
    await DatabaseHelper.instance.setPrBaseline(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((e) => e.id == id ? e.copyWith(hasPrBaseline: true) : e).toList(),
    );
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
