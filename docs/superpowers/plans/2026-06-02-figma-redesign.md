# PeakLog Figma Redesign Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to execute task-by-task.

**Goal:** Rebuild PeakLog UI to match Figma — blue accent, horizontal category chips, repository layer, GoRouter, Bottom Sheets, Profile screen — while preserving all SQLite data.

**Architecture:** UI → Provider → UseCase → Repository → DatabaseHelper → SQLite (single direction). No DB schema changes. Soft-delete only.

**Tech Stack:** Flutter 3, Riverpod, GoRouter, Material3, SQLite (sqflite)

**Figma tokens extracted from screenshots:**
- Accent/Primary: #3478F6 (iOS system blue)
- Background: #F2F2F7
- Card: #FFFFFF
- Label1: #000000, Label2: #8E8E93, Label3: #C7C7CC
- Separator: #E5E5EA
- Destructive: #FF3B30

---

## Task 1: Packages + Design System

**Files:**
- Modify: `pubspec.yaml` — add go_router ^14.0.0
- Create: `lib/core/design/app_colors.dart`
- Create: `lib/core/design/app_typography.dart`
- Create: `lib/core/design/app_spacing.dart`
- Create: `lib/core/design/app_radius.dart`
- Modify: `lib/core/theme/app_theme.dart` — rebuild with Material3 + blue

- [ ] Add `go_router: ^14.0.0` to pubspec.yaml, run `flutter pub get`
- [ ] Create `app_colors.dart`:
```dart
import 'package:flutter/material.dart';
class AppColors {
  AppColors._();
  static const primary     = Color(0xFF3478F6);
  static const primarySoft = Color(0x1A3478F6);
  static const background  = Color(0xFFF2F2F7);
  static const card        = Color(0xFFFFFFFF);
  static const chip        = Color(0xFFE5E5EA);
  static const chipSelected= Color(0xFF000000);
  static const label1      = Color(0xFF000000);
  static const label2      = Color(0xFF8E8E93);
  static const label3      = Color(0xFFC7C7CC);
  static const separator   = Color(0xFFE5E5EA);
  static const destructive = Color(0xFFFF3B30);
  static const success     = Color(0xFF34C759);
}
```
- [ ] Create `app_typography.dart`:
```dart
import 'package:flutter/material.dart';
class AppTypography {
  AppTypography._();
  static const appTitle    = TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const screenTitle = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const pbValue     = TextStyle(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -1.0);
  static const cardValue   = TextStyle(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const headline    = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const cardTitle   = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const body        = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
  static const footnote    = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const caption     = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8);
  static const inputValue  = TextStyle(fontSize: 40, fontWeight: FontWeight.w700);
  static const badge       = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
}
```
- [ ] Create `app_spacing.dart` (4pt grid: s4/s8/s12/s16/s20/s24/s32)
- [ ] Create `app_radius.dart` (card:16, chip:999, button:14, input:12)
- [ ] Rewrite `app_theme.dart`: Material3=true, primary=AppColors.primary, backgroundColor=AppColors.background, cardColor=AppColors.card. AppBar: white bg, black title, blue back arrow. ElevatedButton: blue, rounded14. InputDecoration: card bg, separator border. No orange anywhere.
- [ ] Run `flutter analyze` — 0 errors

---

## Task 2: Repository Layer

**Files:**
- Create: `lib/data/repositories/exercise_repository.dart`
- Create: `lib/data/repositories/record_repository.dart`
- Create: `lib/data/repositories/settings_repository.dart`

Each repository wraps `DatabaseHelper.instance` calls. No logic, pure data access.

- [ ] Create `ExerciseRepository` with: `getAll()`, `insert(Exercise)→Exercise`, `update(Exercise)`, `softDelete(String id)` (sets is_archived=1, no DELETE)
- [ ] Create `RecordRepository` with: `getByExercise(String exerciseId)→List<Record>`, `insert(Record)→Record`, `softDelete(String id)` (sets deleted_at, no DELETE)
- [ ] Create `SettingsRepository` with: `get()→UnitSettings`, `save(UnitSettings)`
- [ ] Run `flutter analyze` — 0 errors

---

## Task 3: UseCases + Updated Providers

**Files:**
- Create: `lib/domain/use_cases/add_exercise_use_case.dart`
- Create: `lib/domain/use_cases/add_record_use_case.dart`
- Modify: `lib/providers/exercises_provider.dart`
- Modify: `lib/providers/records_provider.dart`
- Modify: `lib/providers/unit_settings_provider.dart`

- [ ] `AddExerciseUseCase`: validates name not empty, calls `ExerciseRepository.insert`, returns `Exercise?`
- [ ] `AddRecordUseCase`: inserts record via `RecordRepository`, returns `(Record, bool isPb)` — isPb computed by comparing to previous best from in-memory records list
- [ ] Update providers to call repositories (keep same public API so existing code compiles)
- [ ] `exercisesProvider.addExercise` returns `Exercise?`
- [ ] `recordsProvider.addRecord` returns `Record`
- [ ] Run `flutter analyze` — 0 errors

---

## Task 4: Reusable Widgets

**Files:**
- Create: `lib/widgets/section_label.dart`
- Create: `lib/widgets/pb_badge.dart`
- Create: `lib/widgets/exercise_card.dart` (new Figma design)
- Create: `lib/widgets/history_row.dart`
- Create: `lib/widgets/percent_chip.dart`
- Create: `lib/widgets/menu_tile.dart`
- Create: `lib/widgets/input_card.dart`
- Create: `lib/widgets/empty_state.dart`
- Create: `lib/widgets/save_button.dart`

**SectionLabel**: Text uppercased, AppTypography.caption, AppColors.label2, letterSpacing 0.8.

**PbBadge**: Row with "🏆" emoji + "PB" text in AppColors.primary, AppTypography.badge.

**ExerciseCard** (Figma design):
```
White card, radius16, margin bottom 8, padding 16
├── Row
│   ├── Column (Expanded)
│   │   ├── Text(name, cardTitle, label1)
│   │   ├── Text(value, cardValue, label1) — "160kg" or "3:45"
│   │   └── Row [PbBadge (if hasPb) | Text(dateStr, footnote, label2)]
│   └── Icon(chevron_right, label3, size 16)
```
No category badge. Swipe actions: Edit (blue) + Delete (red).

**HistoryRow** (Figma design):
```
Padding(h16, v12)
Row
├── Column
│   ├── Text("160kg × 1", body, fontWeight.w600)
│   └── Text("Jan 15, 2026", footnote, label2)
└── PbBadge (if isPb)
```
Divider between rows (not below last).

**PercentChip**: GestureDetector, rounded-pill container.
- Selected: black bg, white text, AppTypography.body w600
- Unselected: AppColors.chip bg, label1 text, AppTypography.body w400

**MenuTile**: ListTile with title text (body), trailing chevron (label3), bottom divider. No leading icon.

**InputCard**: White card, padding 16.
- SectionLabel(label) at top
- TextField or Text with AppTypography.inputValue, keyboardType numeric

**EmptyState**: Centered column, icon + "No records yet" text.

**SaveButton**: ElevatedButton full-width, "Save Record", blue, radius14, height 52.

- [ ] Implement all widgets above
- [ ] Run `flutter analyze` — 0 errors

---

## Task 5: Home Screen

**File:** `lib/features/home/home_screen.dart` (full rewrite)

**Layout** (from Figma):
```
Scaffold
  backgroundColor: AppColors.background
  appBar: null (custom header in body)
  body: Column
    ├── SafeArea > Padding(h20,t16)
    │   ├── Row: Text("PeakLog", appTitle) + ProfileButton (circle icon→ProfileScreen)
    │   ├── SizedBox(h16)
    │   ├── SearchBar (white card, radius12, "Search exercises...", search icon)
    │   ├── SizedBox(h12)
    │   └── CategoryFilterRow (horizontal scrollable chips)
    │       All | Weightlifting | Run | Workout
    │       Selected: black fill; Unselected: white border
    └── Expanded > ExerciseList (ListView, padding h16)
        └── ExerciseCard × N
  floatingActionButton: FAB (blue circle, + icon, onTap→AddExerciseSheet)
```

CategoryFilterRow maps ExerciseCategory values + "All". Tapping filters the list.

ExerciseCard uses `ref.watch(recordsProvider(exercise.id))` + `select` for best value.
Date shown as relative: "5 days ago", "2 weeks ago", "1 month ago".

- [ ] Rewrite home_screen.dart to match Figma layout exactly
- [ ] Category filter state managed locally in HomeScreen
- [ ] Search filters by exercise.displayName (case-insensitive)
- [ ] Date formatter util: `DateFormatter.relative(DateTime)` → "5 days ago" etc.
- [ ] Create `lib/core/utils/date_formatter.dart`
- [ ] Run `flutter analyze` — 0 errors

---

## Task 6: Exercise Detail Screen

**File:** `lib/features/exercise_detail/exercise_detail_screen.dart` (full rewrite)

**Layout** (from Figma):
```
Scaffold
  backgroundColor: AppColors.background
  appBar: AppBar
    leading: ← (blue)
    title: Text(exercise.displayName, screenTitle)
    actions: [ShareButton (blue share icon)]
  body: ListView
    ├── SizedBox(h16)
    ├── PersonalBestCard (white card, h16 padding)
    │   ├── SectionLabel("PERSONAL BEST")
    │   ├── SizedBox(h8)
    │   ├── Text(bestValue, pbValue)  — "160kg"
    │   └── Text(dateStr, footnote, label2) — "32 days ago"
    │   (shown only for strength; running/workout shows best time)
    ├── SizedBox(h12) [strength only]
    ├── OneRmCard (white card, strength only)
    │   ├── Row: SectionLabel("1RM CALCULATOR") + TextButton("View Table", primary)
    │   ├── SizedBox(h12)
    │   ├── PercentChipRow (horizontal scroll, 5 chips: 70/75/80/85/90%)
    │   │   selected chip: black; unselected: gray chip bg
    │   ├── SizedBox(h16)
    │   └── Row: Text("$selectedPct %", large gray) + Text(calcWeight, large black bold)
    │       spacing between them
    ├── SizedBox(h24)
    ├── Padding(h16) > SectionLabel("HISTORY")
    ├── SizedBox(h8)
    └── HistoryCard (white card)
        └── HistoryRow × N (with dividers, swipe-to-delete)
```

PercentChipRow: fixed 5 values [70, 75, 80, 85, 90]. Selected percent stored in local state.
OneRm result: `(selectedPct / 100) * bestKg` formatted to display unit.

Share button → existing export/share flow.

- [ ] Rewrite exercise_detail_screen.dart to match Figma
- [ ] History shows format: "160kg × 1" / "Jan 15, 2026"
- [ ] PbBadge shown on history row that is the personal best
- [ ] Delete by swipe (Dismissible), soft-delete via repository
- [ ] Run `flutter analyze` — 0 errors

---

## Task 7: Record Input Bottom Sheet

**File:** `lib/features/record_input/add_record_sheet.dart` (replaces record_input_screen.dart for UI, keep _save logic)

**Layout** (from Figma — Modal Bottom Sheet):
```
showModalBottomSheet (isScrollControlled: true, shape: rounded top corners)
Container
  ├── Padding(h20, t20, b32)
  │   ├── Row: Text("Add Record", headline) + IconButton(X, close)
  │   ├── SizedBox(h20)
  │   ├── InputCard (EXERCISE / exercise.displayName.toUpperCase())
  │   │   — read-only display, not editable
  │   ├── SizedBox(h12)
  │   ├── SegmentedControl (Weight | Time) — blue active, gray inactive
  │   │   shown only for strength (weight/reps vs time toggle)
  │   │   running always shows both distance + time
  │   │   workout always shows time only
  │   ├── SizedBox(h12)
  │   ├── [Weight mode] InputCard(WEIGHT (KG), numeric) + InputCard(REPS, numeric)
  │   │   [Time mode]   TimeInputField (h:m:s)
  │   └── SaveButton("Save Record")
```

On save: calls AddRecordUseCase → if isPb, shows PRCelebrationDialog → pops sheet.

- [ ] Implement add_record_sheet.dart as ModalBottomSheet
- [ ] Keep existing save logic (weight unit conversion, isPb detection, PRCelebrationDialog)
- [ ] ExerciseDetailScreen launches via: `showModalBottomSheet(..., builder: (_) => AddRecordSheet(exercise: exercise))`
- [ ] Run `flutter analyze` — 0 errors

---

## Task 8: 1RM Table Screen

**File:** `lib/features/one_rm/one_rm_table_screen.dart`

**Layout** (from Figma):
```
Scaffold
  appBar: AppBar(← blue, title: "$name — 1RM Table", screenTitle)
  body: ListView (white card outer, padding h16)
    TableCard (white card)
      ListView.builder (50~120%, pairs)
      Each row: [leftPct% | leftWeight || rightPct% | rightWeight]
      Columns: pct(label2, body) | weight(label1, body w600) | divider | pct | weight
      Special 100% row: full-width, muted background (AppColors.chip)
        "100%   160.0kg   Current 1RM"
```

4 columns per row: left pair (50,52,54...) right pair (51,53,55...) — Actually from Figma:
Row i: leftPct=50+i, rightPct=85+i (as seen in screenshot: 50/85, 51/86, ...)
Wait — re-reading Figma: 50% | 80.0kg | 85% | 136.0kg per row. So left column goes 50..84, right column goes 85..120.
Rows: 35 rows for 50-84 on left, 36 rows for 85-120 on right (last row left is empty).
100% row is a special full-width row between the pairs showing "100% 160.0kg Current 1RM".

- [ ] Implement with correct column layout matching Figma screenshot exactly
- [ ] 100% row: spans full width, AppColors.chip background, "Current 1RM" label in label2
- [ ] Scroll to current percent on open
- [ ] Run `flutter analyze` — 0 errors

---

## Task 9: Add Exercise Sheet + Profile Screen + GoRouter

**Files:**
- Create: `lib/features/add_exercise/add_exercise_sheet.dart`
- Create: `lib/features/profile/profile_screen.dart`
- Modify: `lib/app.dart` — GoRouter setup
- Modify: `lib/main.dart` — ProviderScope

**AddExerciseSheet** (ModalBottomSheet):
```
"Add Exercise" title + X close
TextField (Exercise Name)
Category picker (4 tiles: Weightlifting/Run/Workout/Custom)
SaveButton("Add Exercise")
```

**ProfileScreen** (from Figma):
```
Scaffold
  appBar: AppBar(← blue, title: "Profile", screenTitle)
  body: ListView
    ├── ProfileCard (avatar circle gray + name + handle + CopyLinkButton)
    ├── MenuCard: Friends > / Privacy >
    ├── SectionLabel("PREFERENCES")
    ├── MenuCard: Units (kg/lb) > / Apple Health >
    ├── SectionLabel("STORE")
    └── MenuCard: Purchased Frames >
```
Units taps → SettingsScreen. Others show "Coming soon" snack.

**GoRouter** (replace Navigator.push throughout):
```
/ → HomeScreen
/exercise/:id → ExerciseDetailScreen
/exercise/:id/1rm-table → OneRmTableScreen
/profile → ProfileScreen
```
AddRecord and AddExercise remain as ModalBottomSheets (not routes).

- [ ] Implement AddExerciseSheet
- [ ] Implement ProfileScreen (no real data, stubbed where noted)
- [ ] Set up GoRouter in app.dart
- [ ] ProfileButton in HomeScreen navigates to /profile
- [ ] ExerciseCard onTap uses context.go('/exercise/${exercise.id}')
- [ ] "View Table" button in OneRmCard uses context.go('/exercise/$id/1rm-table')
- [ ] Run `flutter analyze` — 0 errors
- [ ] Run `flutter run` — app launches without crash

---

## Done criteria
- `flutter analyze` returns 0 issues
- App launches on iOS simulator
- Home screen matches Figma: PeakLog title, search, category chips, exercise cards with blue PB badge
- Exercise detail matches Figma: PB card, 1RM chips, History rows
- Add Record opens as bottom sheet with blue Save button
- 1RM Table shows 4-column layout with highlighted 100% row
- Profile screen accessible from top-right avatar button
