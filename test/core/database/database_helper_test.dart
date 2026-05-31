import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pbpr/core/database/database_helper.dart';
import 'package:pbpr/core/models/exercise.dart';
import 'package:pbpr/core/models/record.dart';

void main() {
  late DatabaseHelper helper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    helper = DatabaseHelper.instance;
  });

  tearDown(() async {
    final db = await helper.database;
    final path = db.path;
    await helper.close();
    await databaseFactory.deleteDatabase(path);
  });

  test('insert and retrieve exercise', () async {
    const exercise = Exercise(
      name: '스쿼트',
      type: ExerciseType.weight,
      orderIndex: 0,
      createdAt: 1000000,
    );
    final id = await helper.insertExercise(exercise);
    expect(id, greaterThan(0));

    final list = await helper.getExercises();
    expect(list.length, 1);
    expect(list.first.name, '스쿼트');
    expect(list.first.id, id);
  });

  test('exercises ordered by order_index', () async {
    await helper.insertExercise(const Exercise(
      name: 'B', type: ExerciseType.weight, orderIndex: 1, createdAt: 0));
    await helper.insertExercise(const Exercise(
      name: 'A', type: ExerciseType.weight, orderIndex: 0, createdAt: 0));

    final list = await helper.getExercises();
    expect(list[0].name, 'A');
    expect(list[1].name, 'B');
  });

  test('delete exercise also deletes its records', () async {
    final exId = await helper.insertExercise(const Exercise(
      name: 'X', type: ExerciseType.time, orderIndex: 0, createdAt: 0));
    await helper.insertRecord(Record(exerciseId: exId, value: 100, recordedAt: 1000));
    await helper.deleteExercise(exId);

    final exercises = await helper.getExercises();
    expect(exercises.where((e) => e.id == exId), isEmpty);
    final records = await helper.getRecordsForExercise(exId);
    expect(records, isEmpty);
  });

  test('insert and retrieve records', () async {
    final exId = await helper.insertExercise(const Exercise(
      name: 'Run', type: ExerciseType.distance, orderIndex: 0, createdAt: 0));
    final record = Record(exerciseId: exId, value: 5.0, recordedAt: 1000000);
    final rId = await helper.insertRecord(record);
    expect(rId, greaterThan(0));

    final records = await helper.getRecordsForExercise(exId);
    expect(records.length, 1);
    expect(records.first.value, 5.0);
  });

  test('records ordered newest first', () async {
    final exId = await helper.insertExercise(const Exercise(
      name: 'Run', type: ExerciseType.distance, orderIndex: 0, createdAt: 0));
    await helper.insertRecord(Record(exerciseId: exId, value: 5.0, recordedAt: 1000));
    await helper.insertRecord(Record(exerciseId: exId, value: 6.0, recordedAt: 2000));

    final records = await helper.getRecordsForExercise(exId);
    expect(records[0].recordedAt, 2000);
    expect(records[1].recordedAt, 1000);
  });

  test('delete record', () async {
    final exId = await helper.insertExercise(const Exercise(
      name: 'R', type: ExerciseType.weight, orderIndex: 0, createdAt: 0));
    final rId = await helper.insertRecord(
        Record(exerciseId: exId, value: 100, recordedAt: 1000));
    await helper.deleteRecord(rId);
    final records = await helper.getRecordsForExercise(exId);
    expect(records, isEmpty);
  });
}
