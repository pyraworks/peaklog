import 'package:flutter_test/flutter_test.dart';
import 'package:pbpr/core/models/record.dart';

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
}
