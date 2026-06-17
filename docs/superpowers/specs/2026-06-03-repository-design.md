# PeakLog Repository Layer Spec (Stage 3)

**Status:** Approved 2026-06-03 with 3 modifications.

---

## Modifications from review

1. `RecordRepository.softDelete(String id)` — exerciseId removed from signature, handled internally.
2. `PersonalBestRepository.compute(Exercise exercise, List<Record> records)` — exercise replaces (exerciseId + RecordType), extracted internally.
3. `SettingsRepository` — no domain interface. Keep as-is (SharedPreferences, no swap needed).

---

## Structure

```
lib/
  domain/
    repositories/
      exercise_repository.dart         abstract ExerciseRepository
      record_repository.dart           abstract RecordRepository
      category_repository.dart         abstract CategoryRepository
      public_record_repository.dart    abstract PublicRecordRepository
      personal_best_repository.dart    abstract PersonalBestRepository
  data/
    repositories/
      exercise_repository_impl.dart    ExerciseRepositoryImpl implements ExerciseRepository
      record_repository_impl.dart      RecordRepositoryImpl implements RecordRepository
      settings_repository.dart         unchanged
      category_repository_impl.dart    CategoryRepositoryImpl implements CategoryRepository
      public_record_repository_impl.dart PublicRecordRepositoryImpl
      personal_best_repository_impl.dart PersonalBestRepositoryImpl (calculated, no DB)
```

---

## Domain Interfaces

### ExerciseRepository
```dart
abstract class ExerciseRepository {
  Future<List<Exercise>> getAll();
  Future<Exercise> insert(Exercise exercise);
  Future<void> update(Exercise exercise);
  Future<void> softDelete(String id);   // sets is_archived = 1
}
```

### RecordRepository
```dart
abstract class RecordRepository {
  Future<List<Record>> getByExercise(String exerciseId);
  Future<Record> insert(Record record);
  Future<void> softDelete(String id);   // sets is_deleted = 1; exerciseId resolved internally
}
```

### CategoryRepository
```dart
abstract class CategoryRepository {
  Future<List<Category>> getAll();
}
```

### PublicRecordRepository
```dart
abstract class PublicRecordRepository {
  Future<List<PublicRecord>> getAll();
  Future<void> insert(PublicRecord pr);
  Future<void> delete(String exerciseId);
  Future<int> count();
}
```

### PersonalBestRepository
```dart
abstract class PersonalBestRepository {
  PersonalBest? compute(Exercise exercise, List<Record> records);
  // No DB access. Extracts exercise.id + exercise.recordType internally.
}
```

---

## Responsibility Boundaries

| Repo | Does | Never |
|---|---|---|
| Exercise | CRUD, soft-delete | PB calc, UI logic |
| Record | CRUD, soft-delete (by id only) | PB calc, unit conversion |
| Category | Read preset list | Exercise CRUD |
| PublicRecord | CRUD, count | 8-limit enforcement (UseCase's job) |
| PersonalBest | Compute from in-memory records | DB access |
| Settings | Read/write SharedPreferences | Business logic |
