import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/record.dart';
import '../data/repositories/record_repository_impl.dart';

/// Bumped whenever any record is added, updated, or deleted (any exercise).
/// Providers that derive data from the records table (e.g. calendar month
/// summaries) watch this to stay in sync without every mutation call site
/// having to know which derived providers exist and invalidate them by hand.
final recordsRevisionProvider = StateProvider<int>((ref) => 0);

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
    int? sets,
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
      sets: sets,
    );
    await RecordRepositoryImpl.instance.insert(record);
    final current = state.valueOrNull ?? [];
    final updated = [record, ...current]
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    state = AsyncData(updated);
    ref.read(recordsRevisionProvider.notifier).state++;
    return record;
  }

  Future<void> updateRecord(Record record) async {
    await RecordRepositoryImpl.instance.update(record);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      (current.map((r) => r.id == record.id ? record : r).toList())
        ..sort((a, b) => b.performedAt.compareTo(a.performedAt)),
    );
    ref.read(recordsRevisionProvider.notifier).state++;
  }

  Future<void> deleteRecord(String id) async {
    await RecordRepositoryImpl.instance.softDelete(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((r) => r.id != id).toList());
    ref.read(recordsRevisionProvider.notifier).state++;
  }
}

final recordsProvider =
    AsyncNotifierProvider.family<RecordsNotifier, List<Record>, String>(
  RecordsNotifier.new,
);
