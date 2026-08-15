import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:peaklog/core/database/database_helper.dart';
import 'package:peaklog/core/models/exercise.dart';
import 'package:peaklog/core/models/record.dart';
import 'package:peaklog/domain/models/category.dart';
import 'package:peaklog/providers/calendar_month_provider.dart';
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
}
