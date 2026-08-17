/// One cell in the monthly share grid. `day == null` means the cell is
/// outside the current month (a leading/trailing blank), matching how the
/// real Calendar grid pads incomplete rows — it never carries activity.
///
/// [hasNote] mirrors `CalendarDayData.hasNote` — whether that date has one
/// or more Notes, entirely independent of [categoryColorKeys]/[hasPr]. A
/// date can have [hasNote] true with empty [categoryColorKeys] (a Note
/// used as a workout-completed marker with no Record), matching the
/// normal Month View grid exactly.
class MonthShareCell {
  final int? day;
  final List<String> categoryColorKeys;
  final bool hasPr;
  final bool hasNote;

  const MonthShareCell({
    required this.day,
    this.categoryColorKeys = const [],
    this.hasPr = false,
    this.hasNote = false,
  });
}

/// One entry in the legend explaining what a category color means. Reuses
/// the exact existing category name/color — never a new label or color.
class MonthShareCategory {
  final String name;
  final String colorKey;

  const MonthShareCategory({required this.name, required this.colorKey});
}

/// Everything the monthly painter needs to render one image.
///
/// [monthLabel] and [countLabel] are already-formatted strings produced by
/// Calendar's own existing month-title and summary logic — the painter
/// never derives or reinterprets them. [usedCategories] is already
/// deduplicated and ordered — see `buildMonthShareCategories`.
///
/// [workoutDaysLabel]/[prCountLabel] are the same summary split into its
/// two existing localized parts so the painter can place the existing PR
/// trophy icon between them, exactly like the on-screen summary. Both are
/// null when there's no activity this month, in which case [countLabel]
/// (Calendar's existing "no workouts" message) is shown instead.
///
/// [noteLegendLabel] is the already-localized "Note" legend label
/// (`l10n.calendarNoteLegendLabel`), or null to omit that legend entry —
/// see `buildMonthShareShowNoteLegend` for when it's included. It is never
/// a [MonthShareCategory]: a Note is not a workout category, so it's kept
/// as its own separate, optional field rather than added to
/// [usedCategories].
class MonthShareData {
  final String monthLabel;
  final String countLabel;
  final String? workoutDaysLabel;
  final String? prCountLabel;
  final List<String> weekdayLabels; // exactly 7, in display order
  final List<MonthShareCell> cells; // row-major, length is a multiple of 7
  final List<MonthShareCategory> usedCategories;
  final String? noteLegendLabel;

  const MonthShareData({
    required this.monthLabel,
    required this.countLabel,
    this.workoutDaysLabel,
    this.prCountLabel,
    required this.weekdayLabels,
    required this.cells,
    required this.usedCategories,
    this.noteLegendLabel,
  });
}
