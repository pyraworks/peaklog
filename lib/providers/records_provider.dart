import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/record.dart';
import 'personal_best_provider.dart';

class RecordsNotifier extends FamilyAsyncNotifier<List<Record>, String> {
  @override
  Future<List<Record>> build(String exerciseId) async =>
      DatabaseHelper.instance.getRecordsForExercise(exerciseId);

  Future<Record> addRecord({
    required int performedAt,
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distance,
    String? note,
  }) async {
    final record = Record.create(
      exerciseId: arg,
      performedAt: performedAt,
      weight: weight,
      reps: reps,
      durationSeconds: durationSeconds,
      distance: distance,
      note: note,
    );
    await DatabaseHelper.instance.insertRecord(record);
    ref.invalidate(personalBestProvider(arg));
    final current = state.valueOrNull ?? [];
    final updated = [record, ...current]
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    state = AsyncData(updated);
    return record;
  }

  Future<void> deleteRecord(String id) async {
    await DatabaseHelper.instance.softDeleteRecord(id, arg);
    ref.invalidate(personalBestProvider(arg));
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((r) => r.id != id).toList());
  }
}

final recordsProvider =
    AsyncNotifierProvider.family<RecordsNotifier, List<Record>, String>(
  RecordsNotifier.new,
);
