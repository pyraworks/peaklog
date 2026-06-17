import '../../core/models/record.dart';

abstract class RecordRepository {
  Future<List<Record>> getByExercise(String exerciseId);
  Future<Record> insert(Record record);
  Future<void> update(Record record);
  Future<void> softDelete(String id);
}
