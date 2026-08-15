import '../../../core/models/exercise.dart';
import '../../../core/models/record.dart';
import '../../../domain/models/category.dart';
import '../../../providers/calendar_month_provider.dart';
import 'month_share_models.dart';

/// Maps the exact same per-day activity map Calendar's month grid already
/// renders from ([CalendarMonthData.days] — one entry per day that has at
/// least one record, with its category colors and whether a PR was set)
/// into share-image cells. No new activity/PR interpretation, no re-fetch,
/// no re-sort — a day with any number of records/categories still counts
/// and renders exactly once, matching the existing Calendar grid.
///
/// [firstWeekdayOffset] and [daysInMonth] must be the same values Calendar
/// itself already computes for the displayed month (its own
/// `_firstWeekdayOffset`/`_daysInMonth`), so weekday positioning matches
/// on-screen exactly.
List<MonthShareCell> buildMonthShareCells({
  required int firstWeekdayOffset,
  required int daysInMonth,
  required Map<int, CalendarDayData> days,
}) {
  final rowCount = ((firstWeekdayOffset + daysInMonth + 6) ~/ 7).clamp(4, 6);
  return List.generate(rowCount * 7, (i) {
    final day = i - firstWeekdayOffset + 1;
    if (day < 1 || day > daysInMonth) return const MonthShareCell(day: null);
    final activity = days[day];
    return MonthShareCell(
      day: day,
      categoryColorKeys: activity?.categoryColorKeys ?? const [],
      hasPr: activity?.hasPr ?? false,
    );
  });
}

/// Legend entries for categories actually used this month — derived from
/// the exact same [CalendarMonthData.records]/`exerciseMap` already loaded
/// for the grid, plus the full category list Calendar's own on-screen
/// legend already watches (`categoriesProvider`, passed in by the caller —
/// no new fetch here). A category appears at most once, in the same
/// relative order as [categories] (its existing sort_order), and
/// Uncategorized is excluded, matching `_buildLegend`'s existing behavior.
List<MonthShareCategory> buildMonthShareCategories({
  required List<Record> records,
  required Map<String, Exercise> exerciseMap,
  required List<Category> categories,
}) {
  final usedCategoryIds = <String>{};
  for (final record in records) {
    final categoryId = exerciseMap[record.exerciseId]?.categoryId;
    if (categoryId != null) usedCategoryIds.add(categoryId);
  }
  return [
    for (final category in categories)
      if (category.id != Category.uncategorizedId &&
          usedCategoryIds.contains(category.id))
        MonthShareCategory(name: category.name, colorKey: category.color),
  ];
}
