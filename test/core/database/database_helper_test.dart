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
    final exercise = Exercise.create(
      displayName: '스쿼트',
      category: ExerciseCategory.strength,
      orderIndex: 0,
    );
    await helper.insertExercise(exercise);

    final list = await helper.getExercises();
    expect(list.length, 1);
    expect(list.first.displayName, '스쿼트');
    expect(list.first.id, exercise.id);
  });

  test('exercises ordered by order_index', () async {
    await helper.insertExercise(Exercise.create(
        displayName: 'B',
        category: ExerciseCategory.strength,
        orderIndex: 1));
    await helper.insertExercise(Exercise.create(
        displayName: 'A',
        category: ExerciseCategory.strength,
        orderIndex: 0));

    final list = await helper.getExercises();
    expect(list[0].displayName, 'A');
    expect(list[1].displayName, 'B');
  });

  test('archive exercise soft-deletes records', () async {
    final ex = Exercise.create(
        displayName: 'X',
        category: ExerciseCategory.workout,
        orderIndex: 0);
    await helper.insertExercise(ex);
    final record = Record.create(
        exerciseId: ex.id,
        performedAt: 1000000,
        durationSeconds: 300);
    await helper.insertRecord(record);

    await helper.archiveExercise(ex.id);

    final exercises = await helper.getExercises();
    expect(exercises.where((e) => e.id == ex.id), isEmpty);
    final records = await helper.getRecordsForExercise(ex.id);
    expect(records, isEmpty);
  });

  test('insert and retrieve records', () async {
    final ex = Exercise.create(
        displayName: 'Run',
        category: ExerciseCategory.running,
        orderIndex: 0);
    await helper.insertExercise(ex);
    final record = Record.create(
        exerciseId: ex.id,
        performedAt: 1000000,
        distance: 5.0,
        durationSeconds: 1500);
    await helper.insertRecord(record);

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records.length, 1);
    expect(records.first.distance, 5.0);
    expect(records.first.durationSeconds, 1500);
  });

  test('records ordered newest first', () async {
    final ex = Exercise.create(
        displayName: 'Run',
        category: ExerciseCategory.running,
        orderIndex: 0);
    await helper.insertExercise(ex);
    await helper.insertRecord(Record.create(
        exerciseId: ex.id, performedAt: 1000, distance: 5.0));
    await helper.insertRecord(Record.create(
        exerciseId: ex.id, performedAt: 2000, distance: 6.0));

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records[0].performedAt, 2000);
    expect(records[1].performedAt, 1000);
  });

  test('soft delete record hides it from queries', () async {
    final ex = Exercise.create(
        displayName: 'Squat',
        category: ExerciseCategory.strength,
        orderIndex: 0);
    await helper.insertExercise(ex);
    final record = Record.create(
        exerciseId: ex.id,
        performedAt: 1000000,
        weight: 100.0,
        reps: 1);
    await helper.insertRecord(record);

    await helper.softDeleteRecord(record.id, ex.id);

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records, isEmpty);
  });

  test('personal best auto-calculated on insert', () async {
    final ex = Exercise.create(
        displayName: 'Deadlift',
        category: ExerciseCategory.strength,
        orderIndex: 0);
    await helper.insertExercise(ex);

    await helper.insertRecord(Record.create(
        exerciseId: ex.id,
        performedAt: 1000000,
        weight: 100.0,
        reps: 1));
    await helper.insertRecord(Record.create(
        exerciseId: ex.id,
        performedAt: 2000000,
        weight: 120.0,
        reps: 1));

    final pbs = await helper.getPersonalBestsForExercise(ex.id);
    expect(pbs.length, 1);
    expect(pbs.first.value, 120.0);
  });
}
