import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/models/exercise.dart';
import 'package:peaklog/core/models/record.dart';
import 'package:peaklog/domain/models/category.dart';
import 'package:peaklog/features/calendar/share/month_share_builder.dart';
import 'package:peaklog/providers/calendar_month_provider.dart';

void main() {
  Category category({required String id, required String name, String color = 'gold', int sortOrder = 0}) =>
      Category(id: id, name: name, color: color, sortOrder: sortOrder, createdAt: 0, updatedAt: 0);

  Exercise exercise({required String id, String? categoryId}) => Exercise(
        id: id,
        displayName: 'Ex $id',
        normalizedName: 'ex $id',
        categoryId: categoryId,
        recordType: RecordType.weight,
        createdAt: 0,
        updatedAt: 0,
      );

  Record record({required String id, required String exerciseId}) => Record(
        id: id,
        exerciseId: exerciseId,
        performedAt: 1000,
        weight: 10,
        createdAt: 0,
        updatedAt: 0,
      );

  group('buildMonthShareCells', () {
    test('represents the full month, not just a visible week', () {
      // August 2026: 31 days, 1st is a Saturday.
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 5, // Mon-start week: Sat is offset 5
        daysInMonth: 31,
        days: const {},
      );
      final inMonthDays = cells.where((c) => c.day != null).map((c) => c.day).toSet();
      expect(inMonthDays, {for (var d = 1; d <= 31; d++) d});
      // Full weeks only — a 7-day "visible week" would never produce this.
      expect(cells.length % 7, 0);
      expect(cells.length, greaterThan(7));
    });

    test('day numbers land in the correct grid positions for the given offset', () {
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 3,
        daysInMonth: 5,
        days: const {},
      );
      // First 3 cells are blank (offset), then days 1..5.
      expect(cells[0].day, isNull);
      expect(cells[1].day, isNull);
      expect(cells[2].day, isNull);
      expect(cells[3].day, 1);
      expect(cells[4].day, 2);
      expect(cells[5].day, 3);
      expect(cells[6].day, 4);
      expect(cells[7].day, 5);
    });

    test('existing category activity indicators are preserved unchanged', () {
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 0,
        daysInMonth: 3,
        days: const {
          2: CalendarDayData(categoryColorKeys: ['gold', 'teal'], hasPr: false),
        },
      );
      final day2 = cells.firstWhere((c) => c.day == 2);
      expect(day2.categoryColorKeys, ['gold', 'teal']);
    });

    test('existing PR indicator is preserved unchanged', () {
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 0,
        daysInMonth: 3,
        days: const {
          1: CalendarDayData(categoryColorKeys: ['gold'], hasPr: true),
          2: CalendarDayData(categoryColorKeys: ['teal'], hasPr: false),
        },
      );
      expect(cells.firstWhere((c) => c.day == 1).hasPr, isTrue);
      expect(cells.firstWhere((c) => c.day == 2).hasPr, isFalse);
    });

    test(
        'a day is one cell regardless of how many categories/records it represents '
        '(no per-record inflation — matches CalendarMonthData.days being one entry per day)',
        () {
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 0,
        daysInMonth: 3,
        days: const {
          // A day with many categories (i.e. many records) is still a
          // single map entry, exactly as calendar_month_provider.dart
          // already groups by day-of-month.
          1: CalendarDayData(categoryColorKeys: ['gold', 'teal', 'ocean', 'olive'], hasPr: true),
        },
      );
      expect(cells.where((c) => c.day == 1), hasLength(1));
    });

    test('a day with no activity has no color keys and no PR, but is still a real cell', () {
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 0,
        daysInMonth: 3,
        days: const {},
      );
      final day1 = cells.firstWhere((c) => c.day == 1);
      expect(day1.categoryColorKeys, isEmpty);
      expect(day1.hasPr, isFalse);
    });

    test('empty month (no activity at all) still represents every day, all inactive', () {
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 2,
        daysInMonth: 30,
        days: const {},
      );
      final inMonthCells = cells.where((c) => c.day != null).toList();
      expect(inMonthCells, hasLength(30));
      expect(inMonthCells.every((c) => c.categoryColorKeys.isEmpty && !c.hasPr), isTrue);
    });

    test('grid ordering is row-major and ascending by day, matching the on-screen grid', () {
      final cells = buildMonthShareCells(
        firstWeekdayOffset: 0,
        daysInMonth: 10,
        days: const {},
      );
      final dayOrder = cells.where((c) => c.day != null).map((c) => c.day).toList();
      expect(dayOrder, List.generate(10, (i) => i + 1));
    });

    test('row count follows the existing 4..6 clamp used by the real Calendar grid', () {
      // A short month starting near the end of a week still gets at least
      // 4 rows (28 = 4*7); a long month starting late gets up to 6 rows.
      final short = buildMonthShareCells(firstWeekdayOffset: 0, daysInMonth: 28, days: const {});
      expect(short.length, 28); // exactly 4 rows, no padding beyond the month

      final long = buildMonthShareCells(firstWeekdayOffset: 6, daysInMonth: 31, days: const {});
      expect(long.length, 42); // 6 rows
    });

    test('is a pure function of month-level inputs only — no selected-day parameter exists, '
        'so a selected day can never independently change monthly content', () {
      // buildMonthShareCells has no selectedDay/day-context argument at
      // all — calling it twice with identical month-level inputs always
      // produces identical output, by construction.
      final a = buildMonthShareCells(
        firstWeekdayOffset: 1,
        daysInMonth: 15,
        days: const {5: CalendarDayData(categoryColorKeys: ['gold'], hasPr: true)},
      );
      final b = buildMonthShareCells(
        firstWeekdayOffset: 1,
        daysInMonth: 15,
        days: const {5: CalendarDayData(categoryColorKeys: ['gold'], hasPr: true)},
      );
      expect(a.map((c) => c.day).toList(), b.map((c) => c.day).toList());
      expect(a.map((c) => c.hasPr).toList(), b.map((c) => c.hasPr).toList());
      for (var i = 0; i < a.length; i++) {
        expect(a[i].categoryColorKeys, b[i].categoryColorKeys);
      }
    });
  });

  group('buildMonthShareCategories', () {
    test('includes only categories actually used by this month\'s records', () {
      final cat1 = category(id: 'c1', name: 'Strength', sortOrder: 0);
      final cat2 = category(id: 'c2', name: 'Cardio', sortOrder: 1);
      final ex1 = exercise(id: 'e1', categoryId: 'c1');
      final ex2 = exercise(id: 'e2', categoryId: 'c2');
      final out = buildMonthShareCategories(
        records: [record(id: 'r1', exerciseId: 'e1')], // only ex1/cat1 used
        exerciseMap: {'e1': ex1, 'e2': ex2},
        categories: [cat1, cat2],
      );
      expect(out.map((c) => c.name).toList(), ['Strength']);
    });

    test('a category used by multiple records/days appears only once', () {
      final cat = category(id: 'c1', name: 'Strength');
      final ex = exercise(id: 'e1', categoryId: 'c1');
      final out = buildMonthShareCategories(
        records: [
          record(id: 'r1', exerciseId: 'e1'),
          record(id: 'r2', exerciseId: 'e1'),
          record(id: 'r3', exerciseId: 'e1'),
        ],
        exerciseMap: {'e1': ex},
        categories: [cat],
      );
      expect(out, hasLength(1));
    });

    test('reuses the exact existing category name and color, unchanged', () {
      final cat = category(id: 'c1', name: 'My Category', color: 'ocean');
      final ex = exercise(id: 'e1', categoryId: 'c1');
      final out = buildMonthShareCategories(
        records: [record(id: 'r1', exerciseId: 'e1')],
        exerciseMap: {'e1': ex},
        categories: [cat],
      );
      expect(out.single.name, 'My Category');
      expect(out.single.colorKey, 'ocean');
    });

    test('preserves the existing category order (categories list order = sort_order)', () {
      final cat1 = category(id: 'c1', name: 'B', sortOrder: 1);
      final cat2 = category(id: 'c2', name: 'A', sortOrder: 0);
      // categories passed in already-sorted order (as categoriesProvider
      // provides); builder must not re-sort by name or anything else.
      final ex1 = exercise(id: 'e1', categoryId: 'c1');
      final ex2 = exercise(id: 'e2', categoryId: 'c2');
      final out = buildMonthShareCategories(
        records: [record(id: 'r1', exerciseId: 'e1'), record(id: 'r2', exerciseId: 'e2')],
        exerciseMap: {'e1': ex1, 'e2': ex2},
        categories: [cat1, cat2], // cat1 (sortOrder 1) listed before cat2 (sortOrder 0)
      );
      expect(out.map((c) => c.name).toList(), ['B', 'A']);
    });

    test('Uncategorized is excluded, matching the existing on-screen legend', () {
      final uncategorized =
          category(id: Category.uncategorizedId, name: 'Uncategorized');
      final ex = exercise(id: 'e1', categoryId: Category.uncategorizedId);
      final out = buildMonthShareCategories(
        records: [record(id: 'r1', exerciseId: 'e1')],
        exerciseMap: {'e1': ex},
        categories: [uncategorized],
      );
      expect(out, isEmpty);
    });

    test('an exercise with no category (null categoryId) contributes nothing', () {
      final ex = exercise(id: 'e1', categoryId: null);
      final out = buildMonthShareCategories(
        records: [record(id: 'r1', exerciseId: 'e1')],
        exerciseMap: {'e1': ex},
        categories: const [],
      );
      expect(out, isEmpty);
    });

    test('empty month produces an empty legend', () {
      final cat = category(id: 'c1', name: 'Strength');
      final out = buildMonthShareCategories(
        records: const [],
        exerciseMap: const {},
        categories: [cat],
      );
      expect(out, isEmpty);
    });
  });
}
