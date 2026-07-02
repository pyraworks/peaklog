import '../../core/enums/record_type.dart';
import '../../core/models/record.dart';

class PersonalBest {
  final String exerciseId;
  final RecordType recordType;
  final String sourceRecordId;
  final double? weight;
  final int? durationSeconds;
  final int? rounds;
  final int? reps;
  final double? etcValue;
  final int achievedAt;

  const PersonalBest({
    required this.exerciseId,
    required this.recordType,
    required this.sourceRecordId,
    this.weight,
    this.durationSeconds,
    this.rounds,
    this.reps,
    this.etcValue,
    required this.achievedAt,
  });

  static PersonalBest? fromRecords(
    String exerciseId,
    RecordType recordType,
    List<Record> records, {
    bool pbHigherIsBetter = true,
  }) {
    final active = records.where((r) => !r.isDeleted).toList();
    if (active.isEmpty) return null;

    Record? best;

    switch (recordType) {
      case RecordType.weight:
        final candidates = active.where((r) => r.weight != null).toList();
        if (candidates.isEmpty) return null;
        candidates.sort((a, b) {
          final cmp = b.weight!.compareTo(a.weight!);
          if (cmp != 0) return cmp;
          // tie-break: first to achieve wins (performedAt ASC, then createdAt ASC)
          final tCmp = a.performedAt.compareTo(b.performedAt);
          if (tCmp != 0) return tCmp;
          return a.createdAt.compareTo(b.createdAt);
        });
        best = candidates.first;
        return PersonalBest(
          exerciseId: exerciseId,
          recordType: recordType,
          sourceRecordId: best.id,
          weight: best.weight,
          reps: best.reps,
          achievedAt: best.performedAt,
        );

      case RecordType.forTime:
        final candidates = active.where((r) => r.durationSeconds != null).toList();
        if (candidates.isEmpty) return null;
        candidates.sort((a, b) {
          final cmp = a.durationSeconds!.compareTo(b.durationSeconds!);
          if (cmp != 0) return cmp;
          // tie-break: first to achieve wins
          final tCmp = a.performedAt.compareTo(b.performedAt);
          if (tCmp != 0) return tCmp;
          return a.createdAt.compareTo(b.createdAt);
        });
        best = candidates.first;
        return PersonalBest(
          exerciseId: exerciseId,
          recordType: recordType,
          sourceRecordId: best.id,
          durationSeconds: best.durationSeconds,
          achievedAt: best.performedAt,
        );

      case RecordType.etc:
        final candidates = active.where((r) => r.distance != null).toList();
        if (candidates.isEmpty) return null;
        candidates.sort((a, b) {
          // Direction: higher value wins when pbHigherIsBetter, else lower wins.
          final cmp = pbHigherIsBetter
              ? b.distance!.compareTo(a.distance!)
              : a.distance!.compareTo(b.distance!);
          if (cmp != 0) return cmp;
          final tCmp = a.performedAt.compareTo(b.performedAt);
          if (tCmp != 0) return tCmp;
          return a.createdAt.compareTo(b.createdAt);
        });
        best = candidates.first;
        return PersonalBest(
          exerciseId: exerciseId,
          recordType: recordType,
          sourceRecordId: best.id,
          etcValue: best.distance,
          achievedAt: best.performedAt,
        );

      case RecordType.amrap:
        final candidates = active.where((r) => r.rounds != null).toList();
        if (candidates.isEmpty) return null;
        candidates.sort((a, b) {
          final r = b.rounds!.compareTo(a.rounds!);
          if (r != 0) return r;
          final repCmp = (b.reps ?? 0).compareTo(a.reps ?? 0);
          if (repCmp != 0) return repCmp;
          // tie-break: first to achieve wins
          final tCmp = a.performedAt.compareTo(b.performedAt);
          if (tCmp != 0) return tCmp;
          return a.createdAt.compareTo(b.createdAt);
        });
        best = candidates.first;
        return PersonalBest(
          exerciseId: exerciseId,
          recordType: recordType,
          sourceRecordId: best.id,
          rounds: best.rounds,
          reps: best.reps,
          achievedAt: best.performedAt,
        );
    }
  }
}
