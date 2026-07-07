import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:peaklog/core/database/database_helper.dart';
import 'package:peaklog/core/models/exercise.dart';
import 'package:peaklog/core/models/record.dart';
import 'package:peaklog/domain/models/category.dart';
import 'package:peaklog/domain/models/personal_best.dart';

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
      displayName: '내스쿼트_유니크',
      recordType: RecordType.weight,
      categoryId: Category.uncategorizedId,
    );
    await helper.insertExercise(exercise);

    final list = await helper.getExercises();
    final found = list.where((e) => e.id == exercise.id).toList();
    expect(found.length, 1);
    expect(found.first.displayName, '내스쿼트_유니크');
  });

  test('exercises ordered by order_index', () async {
    await helper.insertExercise(Exercise.create(
        displayName: 'ZZZ_B', recordType: RecordType.weight, orderIndex: 100));
    await helper.insertExercise(Exercise.create(
        displayName: 'ZZZ_A', recordType: RecordType.weight, orderIndex: 99));

    final list = await helper.getExercises();
    final custom = list.where((e) => !e.isSystemPreset).toList();
    expect(custom[0].displayName, 'ZZZ_A');
    expect(custom[1].displayName, 'ZZZ_B');
  });

  test('archive exercise soft-deletes records', () async {
    final ex = Exercise.create(
        displayName: 'X', recordType: RecordType.forTime, orderIndex: 0);
    await helper.insertExercise(ex);
    final record = Record.create(
        exerciseId: ex.id, performedAt: 1000000, durationSeconds: 300);
    await helper.insertRecord(record);

    await helper.archiveExercise(ex.id);

    final exercises = await helper.getExercises();
    expect(exercises.where((e) => e.id == ex.id), isEmpty);
    final records = await helper.getRecordsForExercise(ex.id);
    expect(records, isEmpty);
  });

  test('insert and retrieve records with new fields', () async {
    final ex = Exercise.create(
        displayName: 'Run', recordType: RecordType.etc, orderIndex: 0);
    await helper.insertExercise(ex);
    final record = Record.create(
        exerciseId: ex.id,
        performedAt: 1000000,
        distance: 5.0,
        distanceUnit: 'km',
        durationSeconds: 1500);
    await helper.insertRecord(record);

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records.length, 1);
    expect(records.first.distance, 5.0);
    expect(records.first.durationSeconds, 1500);
    expect(records.first.distanceUnit, 'km');
  });

  test('insert and retrieve Weight record with sets', () async {
    final ex = Exercise.create(
        displayName: 'ZZZ_Bench', recordType: RecordType.weight, orderIndex: 0);
    await helper.insertExercise(ex);
    final record = Record.create(
        exerciseId: ex.id,
        performedAt: 1000000,
        weight: 100.0,
        reps: 5,
        sets: 3);
    await helper.insertRecord(record);

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records.length, 1);
    expect(records.first.weight, 100.0);
    expect(records.first.reps, 5);
    expect(records.first.sets, 3);
  });

  test('existing records remain compatible with sets = null', () async {
    final ex = Exercise.create(
        displayName: 'ZZZ_Squat', recordType: RecordType.weight, orderIndex: 0);
    await helper.insertExercise(ex);
    // Simulates a pre-migration record: no sets value supplied at all.
    final record = Record.create(
        exerciseId: ex.id, performedAt: 1000000, weight: 80.0, reps: 5);
    await helper.insertRecord(record);

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records.first.sets, isNull);
  });

  test('PersonalBest for Weight ignores sets entirely', () async {
    final ex = Exercise.create(
        displayName: 'ZZZ_OHP', recordType: RecordType.weight, orderIndex: 0);
    await helper.insertExercise(ex);

    // Lower weight but many sets should NOT outrank a higher weight with 1 set.
    await helper.insertRecord(Record.create(
        exerciseId: ex.id, performedAt: 1000000, weight: 60.0, reps: 5, sets: 10));
    await helper.insertRecord(Record.create(
        exerciseId: ex.id, performedAt: 2000000, weight: 70.0, reps: 5, sets: 1));

    final records = await helper.getRecordsForExercise(ex.id);
    final pb = PersonalBest.fromRecords(ex.id, RecordType.weight, records);
    expect(pb, isNotNull);
    expect(pb!.weight, 70.0);
  });

  test('records ordered newest first', () async {
    final ex = Exercise.create(
        displayName: 'Run', recordType: RecordType.etc, orderIndex: 0);
    await helper.insertExercise(ex);
    await helper.insertRecord(
        Record.create(exerciseId: ex.id, performedAt: 1000, distance: 5.0));
    await helper.insertRecord(
        Record.create(exerciseId: ex.id, performedAt: 2000, distance: 6.0));

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records[0].performedAt, 2000);
    expect(records[1].performedAt, 1000);
  });

  test('soft delete record hides it from queries', () async {
    final ex = Exercise.create(
        displayName: 'Squat', recordType: RecordType.weight, orderIndex: 0);
    await helper.insertExercise(ex);
    final record = Record.create(
        exerciseId: ex.id, performedAt: 1000000, weight: 100.0, reps: 1);
    await helper.insertRecord(record);

    await helper.softDeleteRecord(record.id);

    final records = await helper.getRecordsForExercise(ex.id);
    expect(records, isEmpty);
  });

  test('PersonalBest computed from records (weight type)', () async {
    final ex = Exercise.create(
        displayName: 'ZZZ_Deadlift_Test', recordType: RecordType.weight, orderIndex: 0);
    await helper.insertExercise(ex);

    await helper.insertRecord(Record.create(
        exerciseId: ex.id, performedAt: 1000000, weight: 100.0, reps: 1));
    await helper.insertRecord(Record.create(
        exerciseId: ex.id, performedAt: 2000000, weight: 120.0, reps: 1));

    final records = await helper.getRecordsForExercise(ex.id);
    final pb = PersonalBest.fromRecords(ex.id, RecordType.weight, records);
    expect(pb, isNotNull);
    expect(pb!.weight, 120.0);
  });

  test('categories seeded on open', () async {
    final cats = await helper.getCategories();
    expect(cats.length, 1);
    expect(cats.first.id, Category.uncategorizedId);
    expect(cats.first.name, 'Uncategorized');
  });

  // ── Regression: archived exercise recovery (FK bug) ──────────────────────
  //
  // Bug: _findOrCreateRunningExercise called getExercises() which filters
  // archived exercises. If a running exercise was archived, a new Exercise was
  // created, insertExercise silently ignored it (normalized_name UNIQUE index
  // conflict), and insertRecord failed with FOREIGN KEY constraint failed.

  group('archived exercise recovery — FK regression', () {
    test('findExerciseByNormalizedName finds archived exercises', () async {
      final ex = Exercise.create(
        displayName: '5km Run',
        recordType: RecordType.etc,
        categoryId: Category.uncategorizedId,
      );
      await helper.insertExercise(ex);
      await helper.archiveExercise(ex.id);

      // getExercises() must NOT return archived exercises
      final active = await helper.getExercises();
      expect(active.where((e) => e.id == ex.id), isEmpty,
          reason: 'archived exercise must be hidden from active list');

      // findExerciseByNormalizedName() MUST find it regardless
      final found = await helper.findExerciseByNormalizedName(ex.normalizedName);
      expect(found, isNotNull,
          reason: 'archived exercise must be discoverable by normalized name');
      expect(found!.id, ex.id);
      expect(found.isArchived, isTrue);
    });

    test('unarchiveExercise restores exercise to active list', () async {
      final ex = Exercise.create(
        displayName: '5km Run',
        recordType: RecordType.etc,
        categoryId: Category.uncategorizedId,
      );
      await helper.insertExercise(ex);
      await helper.archiveExercise(ex.id);
      await helper.unarchiveExercise(ex.id);

      final active = await helper.getExercises();
      final found = active.where((e) => e.id == ex.id).firstOrNull;
      expect(found, isNotNull,
          reason: 'unarchived exercise must appear in active list');
      expect(found!.isArchived, isFalse);
    });

    test('insertRecord throws StateError when exercise does not exist in DB',
        () async {
      // This is the guard added by the fix — it turns a silent FK failure into
      // an explicit, diagnosable error.
      final record = Record.create(
        exerciseId: 'nonexistent-uuid-that-is-not-in-db',
        performedAt: 1000000,
        durationSeconds: 1500,
      );
      await expectLater(helper.insertRecord(record), throwsStateError);
    });

    test(
        'health sync: archived exercise is reused, not duplicated, '
        'and record insertion succeeds (no FK error)', () async {
      // Step 1: create "5km Run"
      final original = Exercise.create(
        displayName: '5km Run',
        recordType: RecordType.etc,
        categoryId: Category.uncategorizedId,
      );
      await helper.insertExercise(original);

      // Step 2: user deletes (archives) the exercise
      await helper.archiveExercise(original.id);

      // Step 3: simulate fixed _findOrCreateRunningExercise
      Exercise resolved;
      final existing =
          await helper.findExerciseByNormalizedName(original.normalizedName);
      if (existing != null) {
        if (existing.isArchived) await helper.unarchiveExercise(existing.id);
        resolved = existing;
      } else {
        resolved = Exercise.create(
          displayName: '5km Run',
          recordType: RecordType.etc,
          categoryId: Category.uncategorizedId,
        );
        await helper.insertExercise(resolved);
      }

      // Step 4: same exercise ID must be reused
      expect(resolved.id, original.id,
          reason: 'must reuse original exercise ID, not create a new one');

      // Step 5: no duplicate exercises in the active list
      final allActive = await helper.getExercises();
      final matching = allActive
          .where((e) => e.normalizedName == original.normalizedName)
          .toList();
      expect(matching.length, 1,
          reason: 'exactly one active exercise must exist after recovery');

      // Step 6: record insertion must succeed — no FK error
      final record = Record.create(
        exerciseId: resolved.id,
        performedAt: 1000000,
        distance: 5.0,
        durationSeconds: 1500,
      );
      await expectLater(
        helper.insertRecord(record),
        completes,
        reason: 'insertRecord must not throw a FOREIGN KEY or StateError',
      );

      // Step 7: inserted record must be retrievable
      final records = await helper.getRecordsForExercise(resolved.id);
      expect(records.length, 1);
      expect(records.first.id, record.id);
    });

    test(
        'pre-fix bug simulation: inserting record with orphan exercise ID '
        'is caught by the guard before reaching SQLite FK check', () async {
      // Demonstrates the old failure mode: ConflictAlgorithm.ignore silently
      // skipped the insertExercise, leaving an exercise object whose ID did not
      // exist in the DB. The new StateError guard makes this diagnosable.
      final orphan = Exercise.create(
        displayName: '5km Run',
        recordType: RecordType.etc,
        categoryId: Category.uncategorizedId,
      );
      // Intentionally NOT inserted into DB — mimics the old silent-ignore bug.

      final record = Record.create(
        exerciseId: orphan.id,
        performedAt: 1000000,
        durationSeconds: 1500,
      );
      await expectLater(
        helper.insertRecord(record),
        throwsStateError,
        reason: 'guard must catch orphan exercise ID before SQLite FK error',
      );
    });
  });
}
