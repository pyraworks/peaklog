import 'package:flutter_test/flutter_test.dart';
import 'package:pbpr/core/models/exercise.dart';

void main() {
  const exercise = Exercise(
    id: 1,
    name: '스쿼트',
    type: ExerciseType.weight,
    orderIndex: 0,
    createdAt: 1000000,
  );

  test('toMap includes all fields', () {
    final map = exercise.toMap();
    expect(map['id'], 1);
    expect(map['name'], '스쿼트');
    expect(map['type'], 'weight');
    expect(map['order_index'], 0);
  });

  test('fromMap round-trips correctly', () {
    final map = exercise.toMap();
    final restored = Exercise.fromMap(map);
    expect(restored.name, exercise.name);
    expect(restored.type, exercise.type);
    expect(restored.orderIndex, exercise.orderIndex);
  });

  test('copyWith replaces specified fields', () {
    final updated = exercise.copyWith(name: '데드리프트', orderIndex: 1);
    expect(updated.name, '데드리프트');
    expect(updated.orderIndex, 1);
    expect(updated.type, ExerciseType.weight);
  });

  test('toMap omits id when null', () {
    const noId = Exercise(
      name: 'A',
      type: ExerciseType.time,
      orderIndex: 0,
      createdAt: 0,
    );
    expect(noId.toMap().containsKey('id'), isFalse);
  });
}
