import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:peaklog/core/database/database_helper.dart';
import 'package:peaklog/core/models/exercise.dart';
import 'package:peaklog/core/models/note.dart';
import 'package:peaklog/core/models/record.dart';
import 'package:peaklog/domain/models/category.dart';
import 'package:peaklog/providers/calendar_month_provider.dart';
import 'package:peaklog/providers/notes_provider.dart';
import 'package:peaklog/providers/records_provider.dart';

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

  test(
      'calendarMonthProvider reflects a record deletion made through '
      'recordsProvider without being manually invalidated', () async {
    // hasPrBaseline must be true for personalBestProvider (and thus the
    // calendar's PR indicator) to consider this exercise's records at all.
    final exercise = Exercise.create(
      displayName: 'Calendar_Refresh_Test_Squat',
      recordType: RecordType.weight,
      categoryId: Category.uncategorizedId,
    ).copyWith(hasPrBaseline: true);
    await helper.insertExercise(exercise);
    final record = Record.create(
      exerciseId: exercise.id,
      performedAt: DateTime(2026, 1, 15).millisecondsSinceEpoch,
      weight: 100,
    );
    await helper.insertRecord(record);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    const key = (year: 2026, month: 1);
    // Keep the provider alive across the mutation, the way a mounted
    // CalendarScreen watching it would.
    container.listen(calendarMonthProvider(key), (_, __) {});
    // Prime recordsProvider so personalBestProvider (read synchronously
    // inside calendarMonthProvider.build) sees it already loaded, rather
    // than racing its own first async fetch.
    await container.read(recordsProvider(exercise.id).future);

    final before = await container.read(calendarMonthProvider(key).future);
    expect(before.records.any((r) => r.id == record.id), isTrue);
    // The record is this exercise's only one, so it's the PR — the day
    // cell and month count should reflect that.
    expect(before.days[15]?.hasPr, isTrue);
    expect(before.prCount, 1);

    await container
        .read(recordsProvider(exercise.id).notifier)
        .deleteRecord(record.id);

    final after = await container.read(calendarMonthProvider(key).future);
    expect(after.records.any((r) => r.id == record.id), isFalse);
    // Deleting the PR-holding record must clear its day's PR indicator.
    expect(after.days.containsKey(15), isFalse);
    expect(after.prCount, 0);
  });

  test(
      'calendarMonthProvider moves a record\'s indicator to its new day, '
      'within the same month, made through recordsProvider without being '
      'manually invalidated', () async {
    final exercise = Exercise.create(
      displayName: 'Calendar_Refresh_Test_DateChange',
      recordType: RecordType.weight,
      categoryId: Category.uncategorizedId,
    ).copyWith(hasPrBaseline: true);
    await helper.insertExercise(exercise);
    final record = Record.create(
      exerciseId: exercise.id,
      performedAt: DateTime(2026, 1, 5).millisecondsSinceEpoch,
      weight: 100,
    );
    await helper.insertRecord(record);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    const key = (year: 2026, month: 1);
    container.listen(calendarMonthProvider(key), (_, __) {});
    await container.read(recordsProvider(exercise.id).future);

    final before = await container.read(calendarMonthProvider(key).future);
    expect(before.days.containsKey(5), isTrue);
    expect(before.days.containsKey(20), isFalse);

    final moved = record.copyWith(
      performedAt: DateTime(2026, 1, 20).millisecondsSinceEpoch,
    );
    await container
        .read(recordsProvider(exercise.id).notifier)
        .updateRecord(moved);

    final after = await container.read(calendarMonthProvider(key).future);
    expect(after.days.containsKey(5), isFalse,
        reason: 'old date indicator should be gone immediately');
    expect(after.days.containsKey(20), isTrue,
        reason: 'new date indicator should appear immediately');
    // PR status must follow the record, not stay pinned to the old day.
    expect(after.days[20]?.hasPr, isTrue);
  });

  test(
      'calendarMonthProvider updates both months when a record moves across '
      'a month boundary, made through recordsProvider without being '
      'manually invalidated', () async {
    final exercise = Exercise.create(
      displayName: 'Calendar_Refresh_Test_CrossMonth',
      recordType: RecordType.weight,
      categoryId: Category.uncategorizedId,
    ).copyWith(hasPrBaseline: true);
    await helper.insertExercise(exercise);
    final record = Record.create(
      exerciseId: exercise.id,
      performedAt: DateTime(2026, 1, 5).millisecondsSinceEpoch,
      weight: 100,
    );
    await helper.insertRecord(record);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    const janKey = (year: 2026, month: 1);
    const febKey = (year: 2026, month: 2);
    // Both months watched at once, the way a CalendarScreen kept alive
    // across a month swipe would leave both providers alive.
    container.listen(calendarMonthProvider(janKey), (_, __) {});
    container.listen(calendarMonthProvider(febKey), (_, __) {});
    await container.read(recordsProvider(exercise.id).future);

    final janBefore = await container.read(calendarMonthProvider(janKey).future);
    final febBefore = await container.read(calendarMonthProvider(febKey).future);
    expect(janBefore.days.containsKey(5), isTrue);
    expect(febBefore.days.isEmpty, isTrue);

    final moved = record.copyWith(
      performedAt: DateTime(2026, 2, 10).millisecondsSinceEpoch,
    );
    await container
        .read(recordsProvider(exercise.id).notifier)
        .updateRecord(moved);

    final janAfter = await container.read(calendarMonthProvider(janKey).future);
    final febAfter = await container.read(calendarMonthProvider(febKey).future);
    expect(janAfter.days.containsKey(5), isFalse,
        reason: 'old month indicator should be gone immediately');
    expect(febAfter.days.containsKey(10), isTrue,
        reason: 'new month indicator should appear immediately');
  });

  group('Note indicator', () {
    test('a note-only day produces hasNote without any category indicators '
        'and does not count as a workout day', () async {
      final note = Note.create(
        performedOn: DateTime(2026, 3, 8).millisecondsSinceEpoch,
        title: 'Rest day',
      );
      await helper.insertNote(note);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      const key = (year: 2026, month: 3);

      final data = await container.read(calendarMonthProvider(key).future);
      expect(data.days[8]?.hasNote, isTrue);
      expect(data.days[8]?.categoryColorKeys, isEmpty);
      expect(data.days[8]?.hasPr, isFalse);
      // A note-only day must never be counted as a workout day.
      expect(data.workoutDays, 0);
      expect(data.prCount, 0);
    });

    test('a workout-only day (no notes) has the existing category '
        'indicators and hasNote false', () async {
      final exercise = Exercise.create(
        displayName: 'Calendar_Note_Test_WorkoutOnly',
        recordType: RecordType.weight,
        categoryId: Category.uncategorizedId,
      );
      await helper.insertExercise(exercise);
      await helper.insertRecord(Record.create(
        exerciseId: exercise.id,
        performedAt: DateTime(2026, 3, 8).millisecondsSinceEpoch,
        weight: 50,
      ));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      const key = (year: 2026, month: 3);

      final data = await container.read(calendarMonthProvider(key).future);
      expect(data.days[8]?.categoryColorKeys, isNotEmpty);
      expect(data.days[8]?.hasNote, isFalse);
      expect(data.workoutDays, 1);
    });

    test('a day with both a workout record and a note shows both '
        'indicators, and still counts as exactly one workout day', () async {
      final exercise = Exercise.create(
        displayName: 'Calendar_Note_Test_Both',
        recordType: RecordType.weight,
        categoryId: Category.uncategorizedId,
      );
      await helper.insertExercise(exercise);
      await helper.insertRecord(Record.create(
        exerciseId: exercise.id,
        performedAt: DateTime(2026, 3, 8).millisecondsSinceEpoch,
        weight: 50,
      ));
      await helper.insertNote(Note.create(
        performedOn: DateTime(2026, 3, 8).millisecondsSinceEpoch,
        body: 'Felt strong today',
      ));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      const key = (year: 2026, month: 3);

      final data = await container.read(calendarMonthProvider(key).future);
      expect(data.days[8]?.categoryColorKeys, isNotEmpty);
      expect(data.days[8]?.hasNote, isTrue);
      expect(data.workoutDays, 1, reason: 'the note must not double-count the day');
    });

    test('multiple notes on the same date still produce exactly one day '
        'entry with a single hasNote indicator', () async {
      final day = DateTime(2026, 3, 8).millisecondsSinceEpoch;
      await helper.insertNote(Note.create(performedOn: day, title: 'First'));
      await helper.insertNote(Note.create(performedOn: day, title: 'Second'));
      await helper.insertNote(Note.create(performedOn: day, title: 'Third'));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      const key = (year: 2026, month: 3);

      final data = await container.read(calendarMonthProvider(key).future);
      expect(data.days.keys.where((d) => d == 8), hasLength(1));
      expect(data.days[8]?.hasNote, isTrue);
    });

    test('existing category overflow (more than 4 categories) is unaffected '
        'by a note being present on the same day', () async {
      final categories = [
        for (final color in ['crimson', 'rust', 'gold', 'teal', 'ocean'])
          Category(
            id: 'cat_$color',
            name: color,
            color: color,
            sortOrder: 0,
            createdAt: 0,
            updatedAt: 0,
          ),
      ];
      for (final c in categories) {
        await helper.insertCategory(c);
      }
      final day = DateTime(2026, 3, 8).millisecondsSinceEpoch;
      for (final c in categories) {
        final exercise = Exercise.create(
          displayName: 'Calendar_Note_Test_${c.id}',
          recordType: RecordType.weight,
          categoryId: c.id,
        );
        await helper.insertExercise(exercise);
        await helper.insertRecord(Record.create(
          exerciseId: exercise.id,
          performedAt: day,
          weight: 10,
        ));
      }
      await helper.insertNote(Note.create(performedOn: day, title: 'Note'));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      const key = (year: 2026, month: 3);

      final data = await container.read(calendarMonthProvider(key).future);
      // All 5 categories are still present in the underlying data — the
      // existing 4-visible+overflow "+" behavior is a UI-level concern
      // (_CategoryDots), untouched by this change.
      expect(data.days[8]?.categoryColorKeys, hasLength(5));
      expect(data.days[8]?.hasNote, isTrue);
    });

    test('adding a note through notesProvider updates calendarMonthProvider '
        'reactively, without manual invalidation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const key = (year: 2026, month: 3);
      container.listen(calendarMonthProvider(key), (_, __) {});

      final before = await container.read(calendarMonthProvider(key).future);
      expect(before.days.containsKey(8), isFalse);

      final performedOn = DateTime(2026, 3, 8).millisecondsSinceEpoch;
      await container
          .read(notesProvider(performedOn).notifier)
          .addNote(title: 'New note', body: '');

      final after = await container.read(calendarMonthProvider(key).future);
      expect(after.days[8]?.hasNote, isTrue,
          reason: 'note indicator should appear immediately, matching the '
              'existing record reactive-flow pattern');
    });
  });
}
