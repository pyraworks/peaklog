# PeakLog Screens Spec (Stage 6)

**Status:** Approved 2026-06-03 with 1 modification.

---

## Modification

OneRMTableScreen: receives `exerciseId` only via route. Gets PB via `personalBestProvider(exerciseId)`.

---

## Routing (app.dart — complete)

| Route | Destination |
|---|---|
| `/` | HomeScreen |
| `/exercise/:id` | ExerciseDetailScreen |
| `/exercise/:id/1rm-table` | OneRMTableScreen |
| `/exercise/:id/add-record` | stub → ExerciseDetailScreen (Bottom Sheet from within) |
| `/exercise/:id/record/:rid/edit` | stub → ExerciseDetailScreen |
| `/profile` | ProfileScreen |
| `/share/:recordId` | ExportScreen |
| `/u/:username` | `_PlaceholderScreen` (MVP stub) |
| `/public-records` | `_PlaceholderScreen` (MVP stub) |

---

## New screens

### OneRMTableScreen (`/exercise/:id/1rm-table`)
- Data: `personalBestProvider(exerciseId)` → PB weight, `unitSettingsProvider.select(weightUnit)`
- Renders only for `RecordType.weight` with PB; otherwise EmptyState
- Table: 50%→120%, 100% row highlighted with chip background + "Current 1RM" label

### ProfileScreen (`/profile`)
- Data: none (pure navigation)
- MenuTile("Units →") → `/settings`
- MenuTile("Apple Health →") → HealthSyncScreen push
- MenuTile("Version") → version text

---

## ExerciseDetailScreen changes

1. `exercisesProvider.select(...)` — only watch single exercise by id
2. PB card → `PersonalBestCard` widget
3. 1RM section → `OneRMCalculator` widget (removes local `_selectedPct` state)
4. History `Dismissible` → `SwipeableRow` (onShare → `/share/:id`, onDelete → recordsProvider)
5. Share button → `context.push('/share/${best?.id}')` if best != null

---

## select optimizations

| Location | select |
|---|---|
| `ExerciseDetailScreen` | `exercisesProvider.select(single exercise)` |
| `ExerciseDetailScreen` | `unitSettingsProvider.select(weightUnit)` |
| `features/home/exercise_card.dart` | `unitSettingsProvider.select(weightUnit)` |
