# Repository Layer

PeakLog separates domain interfaces from SQLite implementations.

---

## Structure

```
lib/
  domain/
    repositories/
      exercise_repository.dart          abstract ExerciseRepository
      record_repository.dart            abstract RecordRepository
      category_repository.dart          abstract CategoryRepository
      public_record_repository.dart     abstract PublicRecordRepository
      personal_best_repository.dart     abstract PersonalBestRepository
  data/
    repositories/
      exercise_repository_impl.dart     ExerciseRepositoryImpl
      record_repository_impl.dart       RecordRepositoryImpl
      category_repository_impl.dart     CategoryRepositoryImpl
      public_record_repository_impl.dart
      settings_repository.dart          (no interface — SharedPreferences, no swap needed)
```

---

## Interface Contracts

### ExerciseRepository

```dart
abstract class ExerciseRepository {
  Future<List<Exercise>> getAll();
  Future<Exercise?> getById(String id);
  Future<Exercise> create(Exercise exercise);
  Future<Exercise> update(Exercise exercise);
  Future<void> softDelete(String id);
}
```

### RecordRepository

```dart
abstract class RecordRepository {
  Future<List<Record>> getByExerciseId(String exerciseId);
  Future<Record?> getById(String id);
  Future<Record> create(Record record);
  Future<Record> update(Record record);
  Future<void> softDelete(String id);  // exerciseId not required — resolved internally
}
```

### PersonalBestRepository

```dart
abstract class PersonalBestRepository {
  PersonalBest? compute(Exercise exercise, List<Record> records);
}
```

---

## Rules

**No direct DB access from Providers.** Providers inject via repository providers (interface type), never `RepositoryImpl`.

**softDelete signature:** `RecordRepository.softDelete(String id)` — `exerciseId` is resolved internally by the implementation.

**PersonalBest is computed, not stored.** `PersonalBestRepository.compute(...)` takes an `Exercise` (not just `exerciseId + RecordType`) so it can extract both internally.

**SettingsRepository has no domain interface.** It wraps SharedPreferences. There is no planned swap scenario, so the interface layer adds no value here.

---

## Soft Delete Invariant

`DELETE` SQL is never executed for user data. All deletions set `isDeleted = true` and `updatedAt = now()`.

Records with `isDeleted = true` are excluded from:
- UI list rendering
- PB calculation
- Export and share

They are retained in the DB for:
- Sync conflict resolution
- Audit trail
- Future undelete support
