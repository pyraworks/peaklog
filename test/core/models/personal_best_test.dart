import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/enums/record_type.dart';
import 'package:peaklog/core/models/record.dart';
import 'package:peaklog/domain/models/personal_best.dart';

// Minimal Record factory — only fields needed for PB tests.
Record _rec({
  required String id,
  required double weight,
  int performedAt = 1000000,
  bool isDeleted = false,
  int? reps,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Record(
    id: id,
    exerciseId: 'ex-1',
    performedAt: performedAt,
    weight: weight,
    reps: reps ?? 1,
    isDeleted: isDeleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const exerciseId = 'ex-1';

  group('PersonalBest.fromRecords — weight type', () {
    test('highest weight wins regardless of insertion order', () {
      // Records entered in ascending order — PB must still be the heaviest.
      final records = [
        _rec(id: 'a', weight: 100.0, performedAt: 1000),
        _rec(id: 'b', weight: 150.0, performedAt: 2000),
        _rec(id: 'c', weight: 200.0, performedAt: 3000),
      ];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, records);
      expect(pb?.weight, 200.0);
      expect(pb?.sourceRecordId, 'c');
    });

    test('highest weight wins when records entered in descending order', () {
      final records = [
        _rec(id: 'a', weight: 200.0, performedAt: 1000),
        _rec(id: 'b', weight: 150.0, performedAt: 2000),
        _rec(id: 'c', weight: 100.0, performedAt: 3000),
      ];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, records);
      expect(pb?.weight, 200.0);
      expect(pb?.sourceRecordId, 'a');
    });

    test('highest weight wins when records entered in random order', () {
      final records = [
        _rec(id: 'a', weight: 130.0, performedAt: 2000),
        _rec(id: 'b', weight: 200.0, performedAt: 1000),
        _rec(id: 'c', weight: 80.0,  performedAt: 3000),
        _rec(id: 'd', weight: 165.0, performedAt: 4000),
      ];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, records);
      expect(pb?.weight, 200.0);
      expect(pb?.sourceRecordId, 'b');
    });

    test('deleted records are excluded from PB', () {
      final records = [
        _rec(id: 'a', weight: 100.0),
        _rec(id: 'b', weight: 999.0, isDeleted: true),
        _rec(id: 'c', weight: 150.0),
      ];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, records);
      expect(pb?.weight, 150.0);
      expect(pb?.sourceRecordId, 'c');
    });

    test('single record becomes PB', () {
      final records = [_rec(id: 'only', weight: 120.0)];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, records);
      expect(pb?.weight, 120.0);
    });

    test('returns null when all records are deleted', () {
      final records = [
        _rec(id: 'a', weight: 100.0, isDeleted: true),
        _rec(id: 'b', weight: 200.0, isDeleted: true),
      ];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, records);
      expect(pb, isNull);
    });

    test('returns null for empty list', () {
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, []);
      expect(pb, isNull);
    });

    test('tie-break: earlier performedAt wins when weights are equal', () {
      final records = [
        _rec(id: 'later',   weight: 100.0, performedAt: 2000),
        _rec(id: 'earlier', weight: 100.0, performedAt: 1000),
      ];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.weight, records);
      expect(pb?.sourceRecordId, 'earlier',
          reason: 'first to achieve the weight gets credit on tie');
    });
  });

  group('PersonalBest.fromRecords — amrap type', () {
    Record amrapRec({required String id, required int rounds, int reps = 0, int performedAt = 1000}) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return Record(
        id: id,
        exerciseId: exerciseId,
        performedAt: performedAt,
        rounds: rounds,
        reps: reps,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('most rounds wins', () {
      final records = [
        amrapRec(id: 'a', rounds: 5),
        amrapRec(id: 'b', rounds: 8),
        amrapRec(id: 'c', rounds: 3),
      ];
      final pb = PersonalBest.fromRecords(exerciseId, RecordType.amrap, records);
      expect(pb?.rounds, 8);
      expect(pb?.sourceRecordId, 'b');
    });

    test('deleted records excluded from amrap PB', () {
      // copyWith(isDeleted: true) returns a new object without mutating — verify
      // the real delete path by constructing a Record with isDeleted: true directly
      final now = DateTime.now().millisecondsSinceEpoch;
      final deletedRecord = Record(
        id: 'b',
        exerciseId: exerciseId,
        performedAt: 1000,
        rounds: 99,
        isDeleted: true,
        createdAt: now,
        updatedAt: now,
      );
      final pb = PersonalBest.fromRecords(
          exerciseId, RecordType.amrap, [amrapRec(id: 'a', rounds: 5), deletedRecord]);
      expect(pb?.rounds, 5);
    });
  });
}
