# Running Health Import Spec

**Status:** Approved 2026-06-03 with 3 modifications.

---

## Modifications

1. Dedup: HealthKit workout UUID → `Record.metadataJson = {"healthKitWorkoutId": "..."}`. Check existing records' metadataJson before insert. Hash-based dedup removed.
2. Permissions: WORKOUT + DISTANCE_WALKING_RUNNING only. ACTIVE_ENERGY_BURNED removed.
3. Import target: current exercise only. No exercise selection UI.

---

## Flow

```
AddRecordSheet (RecordType.distance)
  └── "Import from Apple Health" button
        ↓ tap
      HealthPickerSheet
        1. requestPermission([WORKOUT, DISTANCE_WALKING_RUNNING])
        2. fetchRecentRunningWorkouts() → List<HealthWorkout>
        3. Show list (date, distance, duration, already-imported badge)
        4. User selects →
           a. Check Record.metadataJson for duplicate healthKitWorkoutId
           b. If not duplicate: addRecord(distance, duration, performedAt, metadataJson)
           c. Pop sheet
```

---

## HealthWorkout model (ephemeral)

```dart
class HealthWorkout {
  final String workoutId;       // dp.uuid (HealthKit UUID)
  final DateTime startTime;
  final int durationSeconds;
  final double distanceKm;
}
```

---

## Dedup logic

```dart
final existingRecords = ref.read(recordsProvider(exercise.id)).valueOrNull ?? [];
final duplicate = existingRecords.any((r) {
  if (r.metadataJson == null) return false;
  try { return jsonDecode(r.metadataJson!)['healthKitWorkoutId'] == w.workoutId; }
  catch (_) { return false; }
});
```

---

## Files

| File | Change |
|---|---|
| `lib/core/models/health_workout.dart` | NEW ephemeral model |
| `lib/core/services/health_sync_service.dart` | Add `fetchRecentRunningWorkouts()`, permissions update |
| `lib/providers/records_provider.dart` | Add `metadataJson` param to `addRecord()` |
| `lib/features/record_input/health_picker_sheet.dart` | NEW bottom sheet |
| `lib/features/record_input/add_record_sheet.dart` | Add Import button (distance only) |
| `ios/Runner/Info.plist` | Remove `NSHealthUpdateUsageDescription` |
