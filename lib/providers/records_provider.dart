import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/record.dart';
import '../data/repositories/record_repository_impl.dart';

class RecordsNotifier extends FamilyAsyncNotifier<List<Record>, String> {
  @override
  Future<List<Record>> build(String exerciseId) async =>
      DatabaseHelper.instance.getRecordsForExercise(exerciseId);

  Future<Record> addRecord({
    required int performedAt,
    double? weight,
    String weightUnit = 'kg',
    int? reps,
    int? rounds,
    int? durationSeconds,
    int? durationMinutes,
    double? distance,
    String distanceUnit = '',
    String? note,
    String? metadataJson,
    int? timeCap,
  }) async {
    final record = Record.create(
      exerciseId: arg,
      performedAt: performedAt,
      weight: weight,
      weightUnit: weightUnit,
      reps: reps,
      rounds: rounds,
      durationSeconds: durationSeconds,
      durationMinutes: durationMinutes,
      distance: distance,
      distanceUnit: distanceUnit,
      note: note,
      metadataJson: metadataJson,
      timeCap: timeCap,
    );
    await RecordRepositoryImpl.instance.insert(record);
    final current = state.valueOrNull ?? [];
    final updated = [record, ...current]
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    state = AsyncData(updated);
    return record;
  }

  Future<void> updateRecord(Record record) async {
    await RecordRepositoryImpl.instance.update(record);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      (current.map((r) => r.id == record.id ? record : r).toList())
        ..sort((a, b) => b.performedAt.compareTo(a.performedAt)),
    );
  }

  Future<void> deleteRecord(String id) async {
    await RecordRepositoryImpl.instance.softDelete(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((r) => r.id != id).toList());
  }
}

final recordsProvider =
    AsyncNotifierProvider.family<RecordsNotifier, List<Record>, String>(
  RecordsNotifier.new,
);
