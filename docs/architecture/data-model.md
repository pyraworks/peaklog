# Data Model

Confirmed schema for PeakLog. Review before adding any new field or table.

---

## Core Principles

| Rule | Detail |
|------|--------|
| Record = Fact | Store only what happened. No derived values. |
| PersonalBest = Derived | Computed from Records at read time. Never stored on Exercise. |
| SQLite = Source of Truth | Server is sync/share/backup only. |
| Offline First | All core features work without network. |
| UUID PKs | Never `int` PKs. Multi-device sync requires collision-free IDs. |
| Soft Delete | Never `DELETE`. Always `isDeleted = true`. |

---

## Exercise

```dart
class Exercise {
  String id;            // UUID
  String? ownerId;
  String displayName;
  String normalizedName;
  String? categoryId;
  RecordType? recordType;  // null = not yet configured
  String baseUnit;         // 'kg' | 'lbs' | 'km' | 'm'
  bool isArchived;
  int createdAt;           // epoch ms
  int updatedAt;           // epoch ms
  SyncStatus syncStatus;
}
```

**Never store on Exercise:** `currentPB`, `current1RM`, aggregates, statistics.

---

## Record

```dart
class Record {
  String id;              // UUID
  String? ownerId;
  String exerciseId;
  int performedAt;        // epoch ms
  double? weight;         // always kg internally
  String weightUnit;      // display unit: 'kg' | 'lbs'
  int? reps;
  int? rounds;
  int? durationSeconds;
  double? distance;       // always km internally
  String distanceUnit;    // display unit: 'km' | 'm'
  String? note;
  String? metadataJson;
  bool isDeleted;         // soft delete — never hard DELETE
  bool isPrCandidate;     // legacy field — ignored in PB calculation
  int createdAt;          // epoch ms
  int updatedAt;          // epoch ms
  SyncStatus syncStatus;
}
```

**Never:** merge weight/distance/duration into a single `value` field.

---

## PersonalBest

PersonalBest is a **derived, computed model** — not independently writable.

```dart
class PersonalBest {
  String exerciseId;
  String sourceRecordId;   // the Record that holds this PB
  RecordType type;
  double? weight;
  int? rounds;
  int? durationSeconds;
  double? distance;
  int achievedAt;          // epoch ms (from source Record.performedAt)
}
```

Computed by `PersonalBest.fromRecords(exerciseId, recordType, records)`.

**Never store on Exercise.** **Never cache in DB.**

---

## SyncTask

```dart
class SyncTask {
  String id;            // UUID
  String entityType;    // 'exercise' | 'record' | 'profile'
  String entityId;
  String operation;     // 'create' | 'update' | 'delete'
  int retryCount;
  int createdAt;        // epoch ms
  SyncStatus syncStatus; // pending | synced | failed
}
```

---

## SQLite Index Requirements

All of these indexes must exist:

```sql
-- records
CREATE INDEX records_exercise_id ON records(exercise_id);
CREATE INDEX records_owner_id ON records(owner_id);
CREATE INDEX records_performed_at ON records(performed_at);
CREATE INDEX records_updated_at ON records(updated_at);

-- personal_bests
CREATE INDEX personal_bests_exercise_id ON personal_bests(exercise_id);

-- exercises
CREATE INDEX exercises_owner_id ON exercises(owner_id);
```

---

## Preset Exercises

Seeded at first launch. User may modify names or delete.

| Category | Exercises |
|----------|-----------|
| Weightlifting | Back Squat, Front Squat, Deadlift, Bench Press, OHP, Clean, Snatch, Clean & Jerk, Thruster, Push Jerk |
| Run | 1km, 5km, 10km, Half Marathon, Full Marathon |
| Workout | Fran, Grace, Helen, Cindy, Murph, Annie |

---

## Name Normalization

Used for deduplication and search matching only — never for behavior inference.

```dart
String normalize(String input) =>
  input.trim().toLowerCase()
    .replaceAll(RegExp(r'\s+'), '_')
    .replaceAll(RegExp(r'[^a-z0-9_]'), '');
```

Matching priority: exact `normalizedName` → alias table → Levenshtein suggestion UI.
