# Navigation

PeakLog uses GoRouter for declarative routing.

---

## Route Map

```
GoRouter(errorBuilder: _Error404Screen)
  /                               HomeScreen               (no back button)
  /exercise/:id                   ExerciseDetailScreen     (back)
  /exercise/:id/1rm-table         OneRMTableScreen         (back)
  /exercise/:id/record/:rid       RecordDetailScreen       (back)
  /exercise/:id/record/:rid/edit  EditRecordScreen         (back)
  /compare/:id                    CompareScreen            (back)
  /profile                        ProfileScreen            (back)
  /settings                       SettingsScreen           (back)
  /share/:recordId                QuickShareScreen         (back)
  /u/:username                    PublicProfileScreen      (back)     [future]
  /public-records                 PublicRecordsScreen      (back)     [future]
```

---

## Rules

**Back button:** HomeScreen has no back button. All other screens always show back.

**Error handling:** Unknown routes render `_Error404Screen` with a "Go Home" (`context.go('/')`) button.

**Sheet navigation:** Bottom sheets (`showModalBottomSheet`, `showCupertinoModalPopup`) are not GoRouter routes. They are triggered imperatively via helper functions.

**Export screen:** Uses `Navigator.push` (not GoRouter) due to the full-screen modal pattern.

---

## Navigation Helpers

Bottom sheets that appear on multiple screens are extracted as top-level functions:

```dart
showAddRecordSheet(context, ref, exercise)
showEditExerciseSheet(context, exercise)
```

These are not routes — they push modal sheets on top of the current route.

---

## Redirect Rules

Legacy or convenience paths redirect rather than rendering:

| Path | Redirects to |
|------|-------------|
| `/exercise/:id/add-record` | `/exercise/:id` |
| `/exercise/:id/record/:rid/edit` | `/exercise/:id` (after save) |
