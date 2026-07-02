import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/personal_best.dart';
import 'exercises_provider.dart';
import 'records_provider.dart';

final personalBestProvider = Provider.family<PersonalBest?, String>(
  (ref, exerciseId) {
    final records = ref.watch(recordsProvider(exerciseId)).valueOrNull ?? [];
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
    final exercise = exercises.where((e) => e.id == exerciseId).firstOrNull;
    if (exercise == null || exercise.recordType == null) return null;
    if (!exercise.hasPrBaseline) return null;
    return PersonalBest.fromRecords(
      exerciseId,
      exercise.recordType!,
      records,
      pbHigherIsBetter: exercise.pbHigherIsBetter,
    );
  },
);
