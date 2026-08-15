/// One record row as it will appear on the generated share image.
/// Built once from already-loaded Calendar data — never recomputes
/// category, PB/PR, or formatting rules on its own.
class DayShareRecord {
  final String exerciseName;
  final String valueLabel;
  final String? setsLabel;
  final bool isPr;
  final String categoryColorKey;

  const DayShareRecord({
    required this.exerciseName,
    required this.valueLabel,
    required this.setsLabel,
    required this.isPr,
    required this.categoryColorKey,
  });
}

/// One note card as it will appear on the generated share image. Title/body
/// are carried through verbatim from the stored Note — no reformatting.
class DayShareNote {
  final String title;
  final String body;

  const DayShareNote({required this.title, required this.body});
}

/// Everything the day-share painter needs to render one image.
///
/// [dateLabel] is the already-formatted day title (e.g. "8월 15일 (토)")
/// produced by Calendar's own `_selectedDayTitle`, and [recordsSectionLabel]
/// / [notesSectionLabel] are the existing localized section labels — the
/// painter never derives its own copy or formatting, only lays out what
/// it's given.
class DayShareData {
  final String dateLabel;
  final String recordsSectionLabel;
  final List<DayShareRecord> records;
  final String notesSectionLabel;
  final List<DayShareNote> notes;

  const DayShareData({
    required this.dateLabel,
    required this.recordsSectionLabel,
    required this.records,
    required this.notesSectionLabel,
    required this.notes,
  });
}
