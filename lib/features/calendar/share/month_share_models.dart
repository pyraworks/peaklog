/// One cell in the monthly share grid. `day == null` means the cell is
/// outside the current month (a leading/trailing blank), matching how the
/// real Calendar grid pads incomplete rows — it never carries activity.
class MonthShareCell {
  final int? day;
  final List<String> categoryColorKeys;
  final bool hasPr;

  const MonthShareCell({
    required this.day,
    this.categoryColorKeys = const [],
    this.hasPr = false,
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
class MonthShareData {
  final String monthLabel;
  final String countLabel;
  final String? workoutDaysLabel;
  final String? prCountLabel;
  final List<String> weekdayLabels; // exactly 7, in display order
  final List<MonthShareCell> cells; // row-major, length is a multiple of 7
  final List<MonthShareCategory> usedCategories;

  const MonthShareData({
    required this.monthLabel,
    required this.countLabel,
    this.workoutDaysLabel,
    this.prCountLabel,
    required this.weekdayLabels,
    required this.cells,
    required this.usedCategories,
  });
}
