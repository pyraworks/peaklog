# PeakLog SQLite + Models Spec (Stage 2)

**Status:** Approved 2026-06-03 with 3 modifications.

---

## Modifications from review

1. `exercises.category` (legacy DB column) — app code must NOT reference after migration. Only `categoryId` is the source of truth.
2. `ownerId` columns — nullable. `NOT NULL` forbidden in new schema.
3. `normalize()` — must pass 5 test cases (see utils/normalize.dart).

---

## Folder changes

```
lib/
  core/
    enums/
      record_type.dart        NEW  — RecordType enum
      sync_status.dart        NEW  — SyncStatus (moved from exercise.dart)
    utils/
      normalize.dart          NEW  — normalize() function
    models/
      exercise.dart           MOD  — remove category, add recordType/categoryId/isSystemPreset
      record.dart             MOD  — add weightUnit/rounds/distanceUnit/metadataJson; ownerId nullable
    database/
      database_helper.dart    MOD  — v5, PRAGMA FK, migration
  domain/
    models/
      category.dart           NEW  — Category + preset IDs
      personal_best.dart      NEW  — PersonalBest (calculated, no DB) + PbCalculator
      public_record.dart      NEW  — PublicRecord model
  data/
    repositories/
      exercise_repository.dart  MOD — minor
      record_repository.dart    MOD — minor

test/
  core/utils/normalize_test.dart  NEW — 5 test cases
```

---

## DB Schema (v5)

### categories (new)
```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending'
)
```
Seeded with 4 presets on onCreate and onUpgrade.

### exercises (ALTER TABLE ADD COLUMN)
```sql
ALTER TABLE exercises ADD COLUMN record_type TEXT DEFAULT 'weight'
ALTER TABLE exercises ADD COLUMN is_system_preset INTEGER DEFAULT 0
ALTER TABLE exercises ADD COLUMN category_id TEXT
```
UPDATE exercises SET record_type, category_id from legacy category column.

### records (ALTER TABLE ADD COLUMN)
```sql
ALTER TABLE records ADD COLUMN weight_unit TEXT DEFAULT 'kg'
ALTER TABLE records ADD COLUMN rounds INTEGER
ALTER TABLE records ADD COLUMN distance_unit TEXT DEFAULT 'km'
ALTER TABLE records ADD COLUMN metadata_json TEXT
```

### public_records (new)
```sql
CREATE TABLE public_records (
  exercise_id TEXT PRIMARY KEY REFERENCES exercises(id) ON DELETE CASCADE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

### Migration rules
- PRAGMA foreign_keys = ON on every onOpen and onUpgrade
- `personal_bests` and `sync_tasks` tables retained in DB but not used in app code
- ownerId columns: nullable in new tables; old tables retain NOT NULL constraint (cannot ALTER COLUMN in SQLite)

---

## Enums

### RecordType
```dart
enum RecordType { weight, distance, forTime, amrap }
```
Extension: `isTimeBased`, `pbLabel`

### SyncStatus
```dart
enum SyncStatus { pending, synced, failed }
```

---

## Models

### Exercise
- Removed: `category: ExerciseCategory` (app code must not reference)
- Added: `recordType: RecordType`, `categoryId: String?`, `isSystemPreset: bool`
- Changed: `ownerId: String?` (was non-null), `orderIndex` kept for DB ordering

### Record
- Changed: `ownerId: String?`
- Added: `weightUnit: String`, `rounds: int?`, `distanceUnit: String`, `metadataJson: String?`
- Removed from public API: `mediaUrl` (stays in DB, not in model)

### Category
- Preset IDs: `Category.weightliftingId`, `runId`, `wodId`, `customId`
- Static `presets` list for UI iteration

### PersonalBest (calculated)
- No DB. Computed by `PersonalBest.fromRecords(exerciseId, recordType, records)`
- Per-type logic per CLAUDE.md spec

### PublicRecord
- Simple data class: exerciseId, displayOrder, createdAt, updatedAt

---

## normalize() algorithm

```
input → trim → lowercase → & → 'and' → _ → ' ' → strip non-[a-z0-9 ] → spaces → '_' → dedup '_'
```

Handles: spaces, hyphens, underscores, ampersands.
