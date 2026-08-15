import '../../../core/models/exercise.dart';
import '../../../core/models/note.dart';
import '../../../core/models/record.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../l10n/app_localizations.dart';
import 'day_share_models.dart';

/// Builds share-image records from the exact same records, exercise map,
/// and category color keys Calendar Day Detail already loaded via
/// [CalendarMonthData] — no separate data fetch, category lookup, or
/// PB/PR calculation. [prRecordIds] must be the set of record ids already
/// determined to be a PR by `personalBestProvider` (the same check Day
/// Detail uses for its own PR indicator).
///
/// Record ordering is preserved exactly as given in [records].
List<DayShareRecord> buildDayShareRecords({
  required List<Record> records,
  required Map<String, Exercise> exerciseMap,
  required Map<String, String> exerciseColorKeys,
  required Set<String> prRecordIds,
  required AppLocalizations l10n,
}) {
  final result = <DayShareRecord>[];
  for (final record in records) {
    final exercise = exerciseMap[record.exerciseId];
    if (exercise == null) continue;
    result.add(DayShareRecord(
      exerciseName: exercise.displayName,
      valueLabel: _formatValue(record, exercise),
      setsLabel: _formatSets(record, exercise, l10n),
      isPr: exercise.exerciseType == ExerciseType.complete
          ? false
          : prRecordIds.contains(record.id),
      categoryColorKey: exerciseColorKeys[exercise.id] ?? 'gray',
    ));
  }
  return result;
}

/// Builds share-image notes from the exact same list Day Detail already
/// loaded via `notesProvider` — same order, same title/body content,
/// no separate query or sorting rule.
List<DayShareNote> buildDayShareNotes(List<Note> notes) => notes
    .map((n) => DayShareNote(title: n.title, body: n.body))
    .toList();

/// Matches CalendarScreen's own `_formatRecordValue` rules exactly (that
/// method is private to the widget and can't be imported directly).
String _formatValue(Record r, Exercise exercise) {
  if (exercise.exerciseType == ExerciseType.complete) return '✓';
  final rt = exercise.recordType;
  if (rt == null) return '—';
  switch (rt) {
    case RecordType.weight:
      final w = r.weight;
      if (w == null) return '—';
      final formatted = UnitConverter.formatWeight(w, exercise.baseUnit);
      return (r.reps != null && r.reps! > 1)
          ? '$formatted × ${r.reps}'
          : formatted;
    case RecordType.forTime:
      final d = r.durationSeconds;
      return d != null ? UnitConverter.secondsToDisplay(d) : '—';
    case RecordType.etc:
      final dist = r.distance;
      return dist != null
          ? UnitConverter.formatEtc(dist, r.distanceUnit)
          : '—';
    case RecordType.amrap:
      if (r.rounds == null) return '—';
      final extra = r.reps != null && r.reps! > 0 ? ' ${r.reps}' : '';
      return '${r.rounds}R$extra';
  }
}

/// Matches RecordDetailScreen's existing Weight + Sets condition exactly.
String? _formatSets(Record r, Exercise exercise, AppLocalizations l10n) {
  if (exercise.recordType != RecordType.weight) return null;
  if (r.sets == null || r.sets! <= 1) return null;
  return l10n.setsDisplay(r.sets!);
}
