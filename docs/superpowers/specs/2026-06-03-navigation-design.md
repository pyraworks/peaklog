# PeakLog Navigation Spec (Stage 7)

**Status:** Approved 2026-06-03 with 3 modifications.

---

## Modifications from review

1. errorBuilder — 404 screen with "Go Home" button (`context.go('/')`).
2. Back rule — unified: Home has no back button; all other screens always show back.
3. ExportScreen — keep `Navigator.push`; add `// TODO: GoRouter 일원화 시` comment.

---

## GoRouter structure

```
GoRouter(errorBuilder: _Error404Screen)
  /                          HomeScreen         (no back)
  /exercise/:id              ExerciseDetailScreen (back)
  /exercise/:id/1rm-table    OneRMTableScreen    (back)
  /exercise/:id/add-record   redirect → /exercise/:id
  /exercise/:id/record/:rid/edit redirect → /exercise/:id
  /profile                   ProfileScreen       (back)
  /settings                  SettingsScreen      (back)
  /share/:recordId           _PlaceholderScreen  (back)
  /u/:username               _PlaceholderScreen  (back)
  /public-records            _PlaceholderScreen  (back)
```

---

## Navigation rules

| Method | When to use |
|---|---|
| `context.push('/route')` | forward navigation (adds to stack, back works) |
| `context.pop()` | GoRouter back (non-Home screens) |
| `Navigator.pop(context)` | dismiss dialogs and bottom sheets only |
| `context.go('/')` | errorBuilder "Go Home" redirect |

`context.go()` is NOT used for forward navigation to detail screens.

---

## Parameter passing

- Route params: `String` IDs only via `state.pathParameters`
- Complex objects (ExportScreen): `Navigator.push + MaterialPageRoute` — acceptable for MVP

---

## Fixes applied

| File | Change |
|---|---|
| `app.dart` | `errorBuilder` → `_Error404Screen` with "Go Home" button |
| `home_screen.dart` | `context.go('/profile')` → `context.push('/profile')` |
| `home_screen.dart` | `context.go('/exercise/:id')` → `context.push('/exercise/:id')` |
| `features/home/exercise_card.dart` | `context.go(...)` → `context.push(...)` |
| `one_rm_panel.dart` | `Navigator.push(_OneRmTableScreen)` → `context.push('/exercise/$id/1rm-table')` |
| `pr_celebration_dialog.dart` | Add TODO comment |
