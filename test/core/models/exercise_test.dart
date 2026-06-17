import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/models/exercise.dart';
import 'package:peaklog/core/utils/normalize.dart';
import 'package:peaklog/domain/models/category.dart';

void main() {
  test('Exercise.create sets id, normalizedName, timestamps', () {
    final e = Exercise.create(
      displayName: 'Back Squat',
      recordType: RecordType.weight,
      categoryId: Category.weightliftingId,
    );
    expect(e.id.isNotEmpty, isTrue);
    expect(e.normalizedName, 'back_squat');
    expect(e.recordType, RecordType.weight);
    expect(e.categoryId, Category.weightliftingId);
    expect(e.isArchived, isFalse);
  });

  test('toMap/fromMap round-trips correctly', () {
    final e = Exercise.create(
      displayName: 'Deadlift',
      recordType: RecordType.weight,
      categoryId: Category.weightliftingId,
      orderIndex: 1,
    );
    final restored = Exercise.fromMap(e.toMap());
    expect(restored.id, e.id);
    expect(restored.displayName, 'Deadlift');
    expect(restored.normalizedName, 'deadlift');
    expect(restored.recordType, RecordType.weight);
    expect(restored.categoryId, Category.weightliftingId);
    expect(restored.orderIndex, 1);
  });

  test('copyWith replaces specified fields', () {
    final e = Exercise.create(
      displayName: 'Squat',
      recordType: RecordType.weight,
      orderIndex: 0,
    );
    final updated = e.copyWith(displayName: 'Front Squat', orderIndex: 2);
    expect(updated.displayName, 'Front Squat');
    expect(updated.orderIndex, 2);
    expect(updated.id, e.id);
  });

  test('normalize handles spaces and special chars', () {
    expect(normalize('Back Squat'),    'back_squat');
    expect(normalize('Clean & Jerk'), 'clean_and_jerk');
    expect(normalize('Back-Squat'),   'back_squat');
    expect(normalize('  Back  Squat  '), 'back_squat');
    expect(normalize('Back_Squat'),   'back_squat');
  });

  test('fromMap returns null recordType when record_type absent', () {
    final map = {
      'id': 'test-id',
      'owner_id': null,
      'display_name': 'Run 5k',
      'normalized_name': 'run_5k',
      'category': 'running',
      'category_id': Category.runId,
      'record_type': null,
      'is_system_preset': 0,
      'visibility': 'private',
      'is_archived': 0,
      'order_index': 0,
      'created_at': 0,
      'updated_at': 0,
      'sync_status': 'pending',
    };
    final e = Exercise.fromMap(map);
    expect(e.recordType, isNull);
  });

  group('baseUnit', () {
    test('defaults to kg on create', () {
      final e = Exercise.create(
        displayName: 'Bench Press',
        recordType: RecordType.weight,
      );
      expect(e.baseUnit, 'kg');
    });

    test('create accepts lbs', () {
      final e = Exercise.create(
        displayName: 'Bench Press',
        recordType: RecordType.weight,
        baseUnit: 'lbs',
      );
      expect(e.baseUnit, 'lbs');
    });

    test('toMap/fromMap round-trips baseUnit', () {
      final e = Exercise.create(
        displayName: 'Bench Press',
        recordType: RecordType.weight,
        baseUnit: 'lbs',
      );
      final restored = Exercise.fromMap(e.toMap());
      expect(restored.baseUnit, 'lbs');
    });

    test('fromMap defaults to kg when base_unit absent (old DB rows)', () {
      final map = {
        'id': 'x',
        'owner_id': null,
        'display_name': 'Squat',
        'normalized_name': 'squat',
        'category': 'strength',
        'category_id': Category.weightliftingId,
        'record_type': 'weight',
        'is_system_preset': 0,
        'visibility': 'private',
        'is_archived': 0,
        'order_index': 0,
        'created_at': 0,
        'updated_at': 0,
        'sync_status': 'pending',
        // base_unit deliberately absent — simulates pre-v10 DB row
      };
      final e = Exercise.fromMap(map);
      expect(e.baseUnit, 'kg');
    });

    test('copyWith updates baseUnit', () {
      final e = Exercise.create(
        displayName: 'Squat',
        recordType: RecordType.weight,
      );
      final updated = e.copyWith(baseUnit: 'lbs');
      expect(updated.baseUnit, 'lbs');
      expect(updated.id, e.id);
    });
  });
}
