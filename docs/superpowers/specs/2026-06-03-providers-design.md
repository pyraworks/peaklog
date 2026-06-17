# PeakLog Riverpod Providers Spec (Stage 4)

**Status:** Approved 2026-06-03 with 3 modifications.

---

## Modifications from review

1. Providers must NOT reference `RepositoryImpl` directly. Inject via `repositoryProvider` (interface type).
2. `personalBestProvider` → `Provider.family<PersonalBest?, String>` (sync computed value, not async state).
3. `select` principle: use in ExerciseDetail/ExerciseCard for specific fields; HomeScreen uses plain `watch`. No excessive select.

---

## Provider inventory

| Provider | Type | Source |
|---|---|---|
| `exercisesProvider` | `AsyncNotifierProvider` | ExerciseRepositoryImpl (direct DB) |
| `recordsProvider` | `AsyncNotifierProvider.family<String>` | RecordRepositoryImpl |
| `personalBestProvider` | `Provider.family<String>` | computed from records + exercise |
| `unitSettingsProvider` | `AsyncNotifierProvider` | SharedPreferences |
| `categoryRepositoryProvider` | `Provider<CategoryRepository>` | CategoryRepositoryImpl |
| `categoriesProvider` | `AsyncNotifierProvider` | via categoryRepositoryProvider |
| `publicRecordRepositoryProvider` | `Provider<PublicRecordRepository>` | PublicRecordRepositoryImpl |
| `publicRecordsProvider` | `AsyncNotifierProvider` | via publicRecordRepositoryProvider |

---

## personalBestProvider (sync computed)

```dart
final personalBestProvider = Provider.family<PersonalBest?, String>(
  (ref, exerciseId) {
    final records = ref.watch(recordsProvider(exerciseId)).valueOrNull ?? [];
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
    final exercise = exercises.where((e) => e.id == exerciseId).firstOrNull;
    if (exercise == null) return null;
    return PersonalBest.fromRecords(exerciseId, exercise.recordType, records);
  },
);
```

Auto-recomputes whenever `recordsProvider` or `exercisesProvider` emits. Returns `null` during loading.

---

## select usage rules

Apply when a widget uses only a subset of a provider's state:

```dart
// ExerciseDetailScreen — single exercise from list
final exercise = ref.watch(
  exercisesProvider.select((s) =>
    s.valueOrNull?.where((e) => e.id == exerciseId).firstOrNull),
);

// ExerciseCard — only weightUnit from settings
final weightUnit = ref.watch(
  unitSettingsProvider.select((s) => s.valueOrNull?.weightUnit ?? 'kg'),
);
```

Do NOT use select on:
- HomeScreen's full exercise list (all exercises needed)
- `recordsProvider(id)` (already keyed, no benefit)
