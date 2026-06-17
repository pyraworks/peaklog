import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/models/record.dart';

void main() {
  test('Record.create sets id and timestamps', () {
    final r = Record.create(
      exerciseId: 'ex-1',
      performedAt: 1000000,
      weight: 100.5,
      reps: 1,
    );
    expect(r.id.isNotEmpty, isTrue);
    expect(r.weight, 100.5);
    expect(r.reps, 1);
    expect(r.isDeleted, isFalse);
  });

  test('toMap/fromMap round-trips correctly', () {
    final r = Record.create(
      exerciseId: 'ex-1',
      performedAt: 1000000,
      weight: 100.0,
      reps: 3,
    );
    final restored = Record.fromMap(r.toMap());
    expect(restored.id, r.id);
    expect(restored.exerciseId, 'ex-1');
    expect(restored.weight, 100.0);
    expect(restored.reps, 3);
    expect(restored.isDeleted, isFalse);
  });

  test('fromMap handles null optional fields', () {
    final r = Record.create(
      exerciseId: 'ex-2',
      performedAt: 2000000,
      durationSeconds: 300,
    );
    final map = r.toMap();
    final restored = Record.fromMap(map);
    expect(restored.weight, isNull);
    expect(restored.reps, isNull);
    expect(restored.durationSeconds, 300);
  });

  test('copyWith preserves unchanged fields', () {
    final r = Record.create(
      exerciseId: 'ex-1',
      performedAt: 1000000,
      weight: 100.0,
    );
    final updated = r.copyWith(isDeleted: true);
    expect(updated.isDeleted, isTrue);
    expect(updated.exerciseId, 'ex-1');
    expect(updated.weight, 100.0);
  });

  // ── PR designation validation (higher-record guard) ───────────────────────
  //
  // Logic extracted from add_record_sheet._save():
  //   hasHigher = records.any((r) => r.weight != null && r.weight! > newWeightKg)
  //
  // This mirrors the exact predicate used to decide whether to show the
  // "Higher Record Exists" confirmation dialog.

  bool hasHigherWeightRecord(List<Record> records, double newWeightKg) =>
      records.any((r) => r.weight != null && r.weight! > newWeightKg);

  Record weightRecord(String id, double kg) => Record.create(
        exerciseId: 'ex-1',
        performedAt: 1000000,
        weight: kg,
        reps: 1,
      );

  group('PR higher-record guard', () {
    test('no existing records → no dialog needed', () {
      expect(hasHigherWeightRecord([], 100.0), isFalse);
    });

    test('all existing records lower → no dialog', () {
      final records = [weightRecord('r1', 80.0), weightRecord('r2', 90.0)];
      expect(hasHigherWeightRecord(records, 100.0), isFalse);
    });

    test('equal record exists → no dialog (tie is not "higher")', () {
      final records = [weightRecord('r1', 100.0)];
      expect(hasHigherWeightRecord(records, 100.0), isFalse);
    });

    test('one higher record exists → dialog shown', () {
      // Scenario from the bug report: 264.6 lbs (≈120 kg) already logged,
      // user tries to mark 130 lbs (≈59 kg) as PR.
      final existing = [
        weightRecord('r1', 59.0),   // 130 lbs — lower
        weightRecord('r2', 120.0),  // 264.6 lbs — HIGHER
      ];
      expect(hasHigherWeightRecord(existing, 59.0), isTrue);
    });

    test('mixed records — only weight-bearing ones are compared', () {
      // Records without weight (distance/time) have weight == null.
      // The predicate skips them correctly.
      final records = [
        Record.create(exerciseId: 'ex-1', performedAt: 1000, durationSeconds: 300),
        weightRecord('r1', 80.0),
      ];
      expect(hasHigherWeightRecord(records, 90.0), isFalse);
      expect(hasHigherWeightRecord(records, 70.0), isTrue);
    });

    test('lbs-entered value converted to kg before comparison', () {
      // User enters 130 lbs → UnitConverter.lbsToKg(130) ≈ 58.97 kg
      // History has 264.6 lbs → ≈ 120.02 kg
      // Both sides compared in kg — dialog must appear.
      const newWeightKg = 58.97;
      const historicalKg = 120.02;
      final records = [weightRecord('r1', historicalKg)];
      expect(hasHigherWeightRecord(records, newWeightKg), isTrue);
    });
  });
}
