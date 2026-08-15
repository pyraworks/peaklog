import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/models/exercise.dart';
import 'package:peaklog/core/models/note.dart';
import 'package:peaklog/core/models/record.dart';
import 'package:peaklog/features/calendar/share/day_share_builder.dart';
import 'package:peaklog/features/calendar/share/day_share_models.dart';
import 'package:peaklog/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  Note note({
    required String id,
    String title = '',
    String body = '',
    int sortOrder = 0,
  }) =>
      Note(
        id: id,
        performedOn: 1000,
        title: title,
        body: body,
        sortOrder: sortOrder,
        createdAt: 0,
        updatedAt: 0,
      );

  Exercise exercise({
    required String id,
    RecordType? recordType,
    ExerciseType exerciseType = ExerciseType.record,
    String baseUnit = 'kg',
  }) =>
      Exercise(
        id: id,
        displayName: 'Ex $id',
        normalizedName: 'ex $id',
        recordType: recordType,
        exerciseType: exerciseType,
        baseUnit: baseUnit,
        createdAt: 0,
        updatedAt: 0,
      );

  Record record({
    required String id,
    required String exerciseId,
    int performedAt = 1000,
    double? weight,
    int? reps,
    int? sets,
    int? rounds,
    int? durationSeconds,
    double? distance,
    String distanceUnit = 'km',
  }) =>
      Record(
        id: id,
        exerciseId: exerciseId,
        performedAt: performedAt,
        weight: weight,
        reps: reps,
        sets: sets,
        rounds: rounds,
        durationSeconds: durationSeconds,
        distance: distance,
        distanceUnit: distanceUnit,
        createdAt: 0,
        updatedAt: 0,
      );

  test('weight formatting', () {
    final ex = exercise(id: 'e1', recordType: RecordType.weight);
    final r = record(id: 'r1', exerciseId: 'e1', weight: 100);
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.valueLabel, '100 kg');
    expect(out.single.setsLabel, isNull);
  });

  test('weight + sets formatting', () {
    final ex = exercise(id: 'e1', recordType: RecordType.weight);
    final r = record(id: 'r1', exerciseId: 'e1', weight: 100, sets: 3);
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.valueLabel, '100 kg');
    expect(out.single.setsLabel, l10n.setsDisplay(3));
  });

  test('weight with a single set does not show a sets label', () {
    final ex = exercise(id: 'e1', recordType: RecordType.weight);
    final r = record(id: 'r1', exerciseId: 'e1', weight: 100, sets: 1);
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.setsLabel, isNull);
  });

  test('AMRAP formatting', () {
    final ex = exercise(id: 'e1', recordType: RecordType.amrap);
    final r = record(id: 'r1', exerciseId: 'e1', rounds: 12, reps: 5);
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.valueLabel, '12R 5');
  });

  test('For Time formatting', () {
    final ex = exercise(id: 'e1', recordType: RecordType.forTime);
    final r = record(id: 'r1', exerciseId: 'e1', durationSeconds: 330);
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.valueLabel, '05:30');
  });

  test('Distance (etc) formatting', () {
    final ex = exercise(id: 'e1', recordType: RecordType.etc);
    final r = record(id: 'r1', exerciseId: 'e1', distance: 5.2, distanceUnit: 'km');
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.valueLabel, '5.2 km');
  });

  test('Complete records show a checkmark and are never a PR', () {
    final ex = exercise(id: 'e1', exerciseType: ExerciseType.complete, recordType: null);
    final r = record(id: 'r1', exerciseId: 'e1');
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {'r1'}, // even if present, complete exercises never show PR
      l10n: l10n,
    );
    expect(out.single.valueLabel, '✓');
    expect(out.single.isPr, isFalse);
  });

  test('PR indication reflects the caller-supplied prRecordIds only', () {
    final ex = exercise(id: 'e1', recordType: RecordType.weight);
    final prRecord = record(id: 'r1', exerciseId: 'e1', weight: 120);
    final nonPrRecord = record(id: 'r2', exerciseId: 'e1', weight: 90);
    final out = buildDayShareRecords(
      records: [prRecord, nonPrRecord],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {'r1'},
      l10n: l10n,
    );
    expect(out[0].isPr, isTrue);
    expect(out[1].isPr, isFalse);
  });

  test('category color key is carried through from exerciseColorKeys', () {
    final ex = exercise(id: 'e1', recordType: RecordType.weight);
    final r = record(id: 'r1', exerciseId: 'e1', weight: 50);
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'teal'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.categoryColorKey, 'teal');
  });

  test('unmapped color key defaults to gray, matching Calendar Day Detail', () {
    final ex = exercise(id: 'e1', recordType: RecordType.weight);
    final r = record(id: 'r1', exerciseId: 'e1', weight: 50);
    final out = buildDayShareRecords(
      records: [r],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.single.categoryColorKey, 'gray');
  });

  test('record ordering is preserved exactly as given', () {
    final ex = exercise(id: 'e1', recordType: RecordType.weight);
    final r1 = record(id: 'r1', exerciseId: 'e1', weight: 50, performedAt: 3000);
    final r2 = record(id: 'r2', exerciseId: 'e1', weight: 60, performedAt: 1000);
    final r3 = record(id: 'r3', exerciseId: 'e1', weight: 70, performedAt: 2000);
    // Deliberately not sorted by performedAt — the builder must not reorder.
    final out = buildDayShareRecords(
      records: [r1, r2, r3],
      exerciseMap: {'e1': ex},
      exerciseColorKeys: {'e1': 'gold'},
      prRecordIds: {},
      l10n: l10n,
    );
    expect(out.map((r) => r.valueLabel).toList(), ['50 kg', '60 kg', '70 kg']);
  });

  test('empty day produces an empty record list', () {
    final out = buildDayShareRecords(
      records: const [],
      exerciseMap: const {},
      exerciseColorKeys: const {},
      prRecordIds: const {},
      l10n: l10n,
    );
    expect(out, isEmpty);
  });

  test('DayShareData carries its labels through unchanged', () {
    const data = DayShareData(
      dateLabel: 'Mar 14 (Sat)',
      recordsSectionLabel: 'Records',
      records: [],
      notesSectionLabel: 'Notes',
      notes: [],
    );
    expect(data.dateLabel, 'Mar 14 (Sat)');
    expect(data.recordsSectionLabel, 'Records');
    expect(data.notesSectionLabel, 'Notes');
  });

  group('buildDayShareNotes', () {
    test('a note is included with its title and body preserved verbatim', () {
      final out = buildDayShareNotes([
        note(id: 'n1', title: 'Leg day', body: 'Felt strong today.'),
      ]);
      expect(out.single.title, 'Leg day');
      expect(out.single.body, 'Felt strong today.');
    });

    test('multiple notes preserve the given order (no re-sorting)', () {
      // Deliberately passed out of any natural order — the builder must
      // not reorder; ordering is notesProvider's job (sort_order, created_at).
      final out = buildDayShareNotes([
        note(id: 'n3', title: 'Third', sortOrder: 2),
        note(id: 'n1', title: 'First', sortOrder: 0),
        note(id: 'n2', title: 'Second', sortOrder: 1),
      ]);
      expect(out.map((n) => n.title).toList(), ['Third', 'First', 'Second']);
    });

    test('an empty notes list produces an empty result', () {
      // The painter only renders a Notes section when data.notes is
      // non-empty — an empty list here is exactly what suppresses it.
      expect(buildDayShareNotes(const []), isEmpty);
    });

    test('long note content is passed through unmodified', () {
      final longBody = 'word ' * 400; // far beyond what fits in the image
      final out = buildDayShareNotes([note(id: 'n1', body: longBody)]);
      // The data layer must not truncate — bounding long text to the
      // canvas is the painter's job (measured, capped-line layout).
      expect(out.single.body, longBody);
    });

    test('a note with an empty title has an empty title, not a placeholder', () {
      final out = buildDayShareNotes([note(id: 'n1', title: '', body: 'Body only')]);
      expect(out.single.title, '');
      expect(out.single.body, 'Body only');
    });
  });
}
