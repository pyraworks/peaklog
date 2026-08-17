import '../../../core/models/exercise.dart';
import '../../../core/models/record.dart';
import '../../../domain/models/category.dart';
import '../../../providers/calendar_month_provider.dart';
import 'month_share_models.dart';

/// Maps the exact same per-day activity map Calendar's month grid already
/// renders from ([CalendarMonthData.days] — one entry per day that has a
/// record and/or a note, with its category colors, whether a PR was set,
/// and whether it has a note) into share-image cells. No new
/// activity/PR/Note interpretation, no re-fetch, no re-sort — a day with
/// any number of records/categories still counts and renders exactly
/// once, matching the existing Calendar grid, and `hasNote` is carried
/// through unchanged so a Note-only day (e.g. used as a workout-completed
/// marker with no Record) still gets its indicator in the capture, exactly
/// as it already does on-screen.
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
      hasNote: activity?.hasNote ?? false,
    );
  });
}

/// Legend entries for this month's capture — derived from the exact same
/// [CalendarMonthData.records]/`exerciseMap` already loaded for the grid,
/// plus the full category list Calendar's own on-screen legend already
/// watches (`categoriesProvider`, passed in by the caller — no new fetch
/// here). A category appears at most once, in the same relative order as
/// [categories] (its existing sort_order), and Uncategorized is always
/// excluded, matching `_buildLegend`'s existing behavior.
///
/// [includeEmpty] is the Month View capture sheet's "Show empty categories"
/// toggle: false (default) keeps the original behavior of only categories
/// with at least one record this month; true includes every other
/// currently-available category too. It only changes which entries this
/// capture-only legend lists — it never touches stored category data or
/// the on-screen Calendar grid.
List<MonthShareCategory> buildMonthShareCategories({
  required List<Record> records,
  required Map<String, Exercise> exerciseMap,
  required List<Category> categories,
  bool includeEmpty = false,
}) {
  final usedCategoryIds = <String>{};
  for (final record in records) {
    final categoryId = exerciseMap[record.exerciseId]?.categoryId;
    if (categoryId != null) usedCategoryIds.add(categoryId);
  }
  return [
    for (final category in categories)
      if (category.id != Category.uncategorizedId &&
          (includeEmpty || usedCategoryIds.contains(category.id)))
        MonthShareCategory(name: category.name, colorKey: category.color),
  ];
}

/// Whether the Month View capture legend should include the separate Note
/// entry. A Note is never a workout category, so this is deliberately kept
/// out of [buildMonthShareCategories]/[MonthShareCategory] — it drives
/// [MonthShareData.noteLegendLabel] instead.
///
/// Independent of category filtering, and intentionally asymmetric with
/// it:
/// - OFF (`includeEmpty: false`): shown only if the captured month
///   actually has one or more notes ([hasAnyNotes]).
/// - ON (`includeEmpty: true`): always shown, even with zero notes this
///   month — matching how ON already always shows every configured
///   category regardless of whether it has records. This is intentional,
///   not a bug: it does not mean a note exists, only that the "show
///   everything available" mode is on.
bool buildMonthShareShowNoteLegend({
  required bool hasAnyNotes,
  required bool includeEmpty,
}) =>
    includeEmpty || hasAnyNotes;
