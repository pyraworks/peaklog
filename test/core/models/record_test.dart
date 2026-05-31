import 'package:flutter_test/flutter_test.dart';
import 'package:pbpr/core/models/record.dart';

void main() {
  const record = Record(
    id: 1,
    exerciseId: 2,
    value: 100.5,
    recordedAt: 1000000,
  );

  test('toMap includes all fields', () {
    final map = record.toMap();
    expect(map['exercise_id'], 2);
    expect(map['value'], 100.5);
    expect(map['recorded_at'], 1000000);
  });

  test('fromMap handles num value', () {
    final map = {
      'id': 1,
      'exercise_id': 2,
      'value': 100,
      'recorded_at': 1000000,
      'note': null,
    };
    final r = Record.fromMap(map);
    expect(r.value, 100.0);
    expect(r.value, isA<double>());
  });

  test('copyWith preserves unchanged fields', () {
    final updated = record.copyWith(value: 110.0);
    expect(updated.value, 110.0);
    expect(updated.exerciseId, 2);
  });
}
