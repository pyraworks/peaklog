import '../../core/database/database_helper.dart';
import '../../core/models/record.dart';
import '../../domain/repositories/record_repository.dart';

class RecordRepositoryImpl implements RecordRepository {
  const RecordRepositoryImpl._();
  static const RecordRepositoryImpl instance = RecordRepositoryImpl._();

  @override
  Future<List<Record>> getByExercise(String exerciseId) =>
      DatabaseHelper.instance.getRecordsForExercise(exerciseId);

  @override
  Future<Record> insert(Record record) async {
    await DatabaseHelper.instance.insertRecord(record);
    return record;
  }

  @override
  Future<void> update(Record record) =>
      DatabaseHelper.instance.updateRecord(record);

  @override
  Future<void> softDelete(String id) =>
      DatabaseHelper.instance.softDeleteRecord(id);
}
