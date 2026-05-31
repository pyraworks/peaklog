import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/record.dart';

class RecordsNotifier extends FamilyAsyncNotifier<List<Record>, int> {
  @override
  Future<List<Record>> build(int exerciseId) async {
    return DatabaseHelper.instance.getRecordsForExercise(exerciseId);
  }

  Future<Record> addRecord(double value, int recordedAt) async {
    final exerciseId = arg;
    final record = Record(
      exerciseId: exerciseId,
      value: value,
      recordedAt: recordedAt,
    );
    final id = await DatabaseHelper.instance.insertRecord(record);
    final saved = record.copyWith(id: id);
    final current = state.valueOrNull ?? [];
    final updated = [saved, ...current]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    state = AsyncData(updated);
    return saved;
  }

  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((r) => r.id != id).toList());
  }
}

final recordsProvider =
    AsyncNotifierProvider.family<RecordsNotifier, List<Record>, int>(
  RecordsNotifier.new,
);
