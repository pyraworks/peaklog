import '../../core/models/exercise.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> getAll();
  Future<Exercise> insert(Exercise exercise);
  Future<void> update(Exercise exercise);
  Future<void> updateRecordType(String id, RecordType rt);
  Future<void> softDelete(String id);
}
