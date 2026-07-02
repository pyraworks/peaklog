import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/exercise.dart';
import '../core/models/record.dart';
import 'categories_provider.dart';
import 'exercises_provider.dart';
import 'personal_best_provider.dart';

typedef YearMonth = ({int year, int month});

class CalendarDayData {
  final List<String> categoryColorKeys; // color key per distinct category, max 4 + overflow
  final bool hasPr;

  const CalendarDayData({
    required this.categoryColorKeys,
    required this.hasPr,
  });
}

class CalendarMonthData {
  final Map<int, CalendarDayData> days;     // day-of-month → summary
  final List<Record> records;               // all non-deleted records in the month
  final Map<String, Exercise> exerciseMap;  // exerciseId → Exercise
  final Map<String, String> exerciseColorKeys; // exerciseId → color key string
  final int workoutDays;
  final int prCount;

  const CalendarMonthData({
    required this.days,
    required this.records,
    required this.exerciseMap,
    required this.exerciseColorKeys,
    required this.workoutDays,
    required this.prCount,
  });
}

class CalendarMonthNotifier
    extends AutoDisposeFamilyAsyncNotifier<CalendarMonthData, YearMonth> {
  @override
  Future<CalendarMonthData> build(YearMonth arg) async {
    final exercises = await ref.watch(exercisesProvider.future);
    final categories = await ref.watch(categoriesProvider.future);

    final startMs = DateTime(arg.year, arg.month).millisecondsSinceEpoch;
    final endMs = DateTime(arg.year, arg.month + 1).millisecondsSinceEpoch;
    final monthRecords =
        await DatabaseHelper.instance.getRecordsByDateRange(startMs, endMs);

    // categoryId → color key
    final catColorMap = {for (final c in categories) c.id: c.color};

    final exMap = {for (final e in exercises) e.id: e};

    // exerciseId → color key (via category)
    final exerciseColorKeys = <String, String>{
      for (final e in exercises)
        e.id: catColorMap[e.categoryId] ?? 'gray',
    };

    // Check PR status only for exercises present in this month
    final monthExerciseIds = monthRecords.map((r) => r.exerciseId).toSet();
    final prRecordIds = <String>{};
    for (final exId in monthExerciseIds) {
      final pb = ref.watch(personalBestProvider(exId));
      if (pb != null) prRecordIds.add(pb.sourceRecordId);
    }

    // Group by day-of-month
    final Map<int, ({Set<String> catIds, bool hasPr})> acc = {};
    for (final record in monthRecords) {
      final day = DateTime.fromMillisecondsSinceEpoch(record.performedAt).day;
      final entry = acc[day] ?? (catIds: {}, hasPr: false);
      final exercise = exMap[record.exerciseId];
      final catId = exercise?.categoryId;
      final isThisPr = prRecordIds.contains(record.id);
      acc[day] = (
        catIds: catId != null ? {...entry.catIds, catId} : entry.catIds,
        hasPr: entry.hasPr || isThisPr,
      );
    }

    final days = acc.map((day, entry) {
      final colorKeys = entry.catIds
          .map((cid) => catColorMap[cid] ?? 'gray')
          .toList();
      return MapEntry(
        day,
        CalendarDayData(categoryColorKeys: colorKeys, hasPr: entry.hasPr),
      );
    });

    return CalendarMonthData(
      days: days,
      records: monthRecords,
      exerciseMap: exMap,
      exerciseColorKeys: exerciseColorKeys,
      workoutDays: days.length,
      prCount: days.values.where((d) => d.hasPr).length,
    );
  }
}

final calendarMonthProvider = AutoDisposeAsyncNotifierProvider.family<
    CalendarMonthNotifier, CalendarMonthData, YearMonth>(
  CalendarMonthNotifier.new,
);
