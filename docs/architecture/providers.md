# Providers

PeakLog uses Riverpod for state management.

---

## Provider Inventory

| Provider | Type | Source |
|----------|------|--------|
| `exercisesProvider` | `AsyncNotifierProvider<List<Exercise>>` | ExerciseRepositoryImpl |
| `recordsProvider` | `AsyncNotifierProvider.family<List<Record>, String>` | RecordRepositoryImpl (by exerciseId) |
| `personalBestProvider` | `Provider.family<PersonalBest?, String>` | computed from records + exercise |
| `unitSettingsProvider` | `AsyncNotifierProvider<UnitSettings>` | SharedPreferences |
| `categoryRepositoryProvider` | `Provider<CategoryRepository>` | CategoryRepositoryImpl |
| `categoriesProvider` | `AsyncNotifierProvider<List<Category>>` | via categoryRepositoryProvider |

---

## personalBestProvider

`personalBestProvider` is a **synchronous computed provider** — not async.

It derives the current PB by reading the records list and calling `PersonalBest.fromRecords(...)`.
No DB query. No separate cache.

```dart
final personalBestProvider = Provider.family<PersonalBest?, String>((ref, exerciseId) {
  final exercise = ref.watch(exercisesProvider.select(...));
  final records = ref.watch(recordsProvider(exerciseId)).valueOrNull ?? [];
  if (exercise?.recordType == null) return null;
  return PersonalBest.fromRecords(exerciseId, exercise!.recordType!, records);
});
```

---

## Rules

**Injection:** Providers must not reference `RepositoryImpl` classes directly. Inject via the repository provider (interface type).

**select:** Use `ref.watch(provider.select(...))` when watching a specific field to avoid unnecessary rebuilds. Use plain `ref.watch` only when the full list is needed (e.g. HomeScreen exercise list).

**No over-selection:** Do not add `.select` everywhere mechanically. Add it where a targeted rebuild matters.

---

## Rebuild Hygiene

A single record addition must not trigger a full-app rebuild.

Pattern:
- `recordsProvider` is family-keyed by `exerciseId` — only screens watching that exercise rebuild.
- `personalBestProvider` re-computes only when `recordsProvider(exerciseId)` changes.
- `exercisesProvider` rebuild is limited by `.select` in detail screens.
