import '../../core/database/database_helper.dart';
import '../../core/models/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  const ExerciseRepositoryImpl._();
  static const ExerciseRepositoryImpl instance = ExerciseRepositoryImpl._();

  @override
  Future<List<Exercise>> getAll() =>
      DatabaseHelper.instance.getExercises();

  @override
  Future<Exercise> insert(Exercise exercise) async {
    await DatabaseHelper.instance.insertExercise(exercise);
    return exercise;
  }

  @override
  Future<void> update(Exercise exercise) =>
      DatabaseHelper.instance.updateExercise(exercise);

  @override
  Future<void> updateRecordType(String id, RecordType rt) =>
      DatabaseHelper.instance.updateExerciseRecordType(id, rt);

  @override
  Future<void> softDelete(String id) =>
      DatabaseHelper.instance.archiveExercise(id);
}
