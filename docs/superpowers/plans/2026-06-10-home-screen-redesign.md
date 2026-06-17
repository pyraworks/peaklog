# Home Screen Redesign — Compact Row Layout + Category Colors

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace card-based exercise list with compact swipeable rows, add per-category color dots, chip-based filter bar, and color picker in category management.

**Architecture:** Add a `color` string field to the `Category` model backed by a named-palette key ('amber', 'red', …). Migrate the DB to v13. Redesign `HomeScreen` to use horizontal category chips (from `categoriesProvider`) and compact `_ExerciseRow` + `SwipeableRow`. Update `CategoryManagementScreen` and `AddExerciseSheet` to show/set colors.

**Tech Stack:** Flutter, Riverpod, sqflite, flutter_slidable (already installed), go_router

---

## File Map

| File | Change |
|------|--------|
| `lib/domain/models/category.dart` | Add `color` field, `CategoryColor` palette helper, `copyWith()`, 6 new preset categories |
| `lib/core/database/database_helper.dart` | Version 12→13 migration: add `color` column, set colors for legacy preset IDs |
| `lib/features/home/home_screen.dart` | Chip filter (from `categoriesProvider`), `_ExerciseRow`, `SwipeableRow` |
| `lib/features/categories/category_management_screen.dart` | Color dot on tile, color picker in add/edit sheet |
| `lib/features/home/add_exercise_sheet.dart` | Read categories from `categoriesProvider`, show color dots |

---

## PB / PR Rendering Reference

Verified by reading `record.dart`, `personal_best.dart`, `add_record_sheet.dart`, `health_sync_service.dart`, and `home_screen.dart`. Code references below are to those files.

### Home row rendering rule

- `hasPb == true` and `bestValue != '—'` → amber trophy icon + `bestValue` text
- `hasPb == false` and `bestValue != '—'` → plain `bestValue` in `label2` color (best record fallback)
- `bestValue == '—'` → nothing shown before the chevron

### Storage and display — full breakdown

| RecordType | User inputs | What is stored | PB determined by | Home screen shows | Example |
|---|---|---|---|---|---|
| `weight` | weight (kg or lb) + reps | `weight` (double, **always kg**); `reps` (int); `weightUnit` | `pb.weight` (highest kg) | `formatWeight(pb.weight, baseUnit)` | `"120 kg"` / `"264 lb"` |
| `distance` | distance (km or mi) | `distance` (double, **always km**); `distanceUnit`; `durationSeconds` = **null for manual entries** | `pb.durationSeconds` (shortest time) | `secondsToDisplay(pb.durationSeconds)` | `"19:42"` / `"1:03:22"` |
| `forTime` | time (duration) | `durationSeconds` (int, seconds) | `pb.durationSeconds` (shortest time) | `secondsToDisplay(pb.durationSeconds)` | `"12:30"` / `"1:03:22"` |
| `amrap` | rounds + reps | `rounds` (int); `reps` (int); `durationSeconds` = **null** | `pb.rounds` (most rounds) | `"${pb.rounds} rounds"` | `"15 rounds"` |
| `null` | — | — | — | `"—"` | `"—"` |

### Critical notes on `distance`

`RecordType.distance` is used for fixed-distance exercises (e.g. "5K Run"). The performance metric is **time**, not distance.

- **Manual input** (`add_record_sheet.dart:309-317`): user enters the distance value only. `durationSeconds` is **never set**. `PersonalBest.fromRecords` filters `r.durationSeconds != null` (`personal_best.dart:62`), so **manual distance entries never generate a PB** and always show `"—"` on the home row.
- **Health import** (`health_sync_service.dart:205-210`): sets both `distance` (km) and `durationSeconds`. These records produce a PB and show time on the home row.
- The stored `distance` field (km) is **not displayed anywhere** — neither on home nor in exercise detail. It is metadata only.

### `secondsToDisplay` output format

`UnitConverter.secondsToDisplay(int totalSeconds)` (`unit_converter.dart:10-18`):
- < 1 hour: `"MM:SS"` e.g. `"19:42"`, `"07:05"`
- ≥ 1 hour: `"H:MM:SS"` e.g. `"1:03:22"`

### Known bug (pre-existing, not introduced by this plan)

`exercise_detail_screen.dart:_formatHistoryValue` falls through `distance`/`forTime`/`amrap` into the same branch that checks `durationSeconds != null`. Since amrap records never have `durationSeconds`, the exercise detail history list always shows `"—"` for amrap entries. The home screen's `_bestValue` is correct (`pb.rounds` path). This bug is out of scope for the current plan.

### Reps on home vs. detail

The home screen `_bestValue` for `weight` shows weight only (`"120 kg"`) — reps are not included. Exercise detail's `_formatHistoryValue` includes reps if > 1 (`"120 kg × 3"`). This asymmetry is intentional and preserved by the plan.

---

## Seeded Categories (new installs only)

These 6 categories are seeded via `_onCreate` for new installs. Existing installs keep their current categories unchanged — the v13 migration only adds the `color` column and sets colors for existing preset rows.

| ID constant | DB id | Name | Color key |
|-------------|-------|------|-----------|
| `weightliftingId` | `preset-category-weightlifting` | Weightlifting | `amber` |
| `powerliftingId` | `preset-category-powerlifting` | Powerlifting | `red` |
| `runningId` | `preset-category-running` | Running | `blue` |
| `crossfitId` | `preset-category-crossfit` | CrossFit | `green` |
| `gymnasticsId` | `preset-category-gymnastics` | Gymnastics | `purple` |
| `otherId` | `preset-category-other` | Other | `gray` |

Old static IDs (`runId`, `wodId`, `customId`) are **kept in the model** because `exercise.dart:_legacyCategoryName` still references them for legacy data mapping. They are not removed.

---

## Design constraints (explicitly documented)

**Flat list — no section headers.** The home screen `ListView.separated` is a single flat list. There are no sticky headers, no `SliverGroup`, no grouping by category. Category information is conveyed by the colored dot on each row only.

**Chips are always horizontally scrollable.** `_CategoryChip` rows use `ListView(scrollDirection: Axis.horizontal)` which handles unlimited categories without overflow or wrapping to a second line.

---

## Task 1: Add `color` field to the Category model

**Files:**
- Modify: `lib/domain/models/category.dart`

- [ ] **Step 1: Replace the file content**

```dart
import '../../core/enums/sync_status.dart';
import 'package:flutter/material.dart';

/// Fixed 8-color palette. Colors are stored as named keys (e.g. 'amber').
class CategoryColor {
  CategoryColor._();

  static const palette = [
    'amber', 'red', 'blue', 'green', 'purple', 'pink', 'gray', 'brown',
  ];

  static Color toColor(String? key) => switch (key) {
    'amber'  => const Color(0xFFF59E0B),
    'red'    => const Color(0xFFEF4444),
    'blue'   => const Color(0xFF3B82F6),
    'green'  => const Color(0xFF22C55E),
    'purple' => const Color(0xFFA855F7),
    'pink'   => const Color(0xFFEC4899),
    'gray'   => const Color(0xFF8E8E93),
    'brown'  => const Color(0xFF92400E),
    _        => const Color(0xFF8E8E93),
  };
}

class Category {
  // ── Current preset IDs ───────────────────────────────────────────
  static const weightliftingId = 'preset-category-weightlifting';
  static const powerliftingId  = 'preset-category-powerlifting';
  static const runningId       = 'preset-category-running';
  static const crossfitId      = 'preset-category-crossfit';
  static const gymnasticsId    = 'preset-category-gymnastics';
  static const otherId         = 'preset-category-other';

  // ── Legacy IDs — kept for exercise.dart backward compat only ─────
  // exercise.dart:_legacyCategoryName still maps old exercises to these IDs.
  // Do not remove.
  static const runId    = 'preset-category-run';
  static const wodId    = 'preset-category-wod';
  static const customId = 'preset-category-custom';

  final String id;
  final String name;
  final String color; // a key from CategoryColor.palette
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const Category({
    required this.id,
    required this.name,
    this.color = 'gray',
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'sort_order': sortOrder,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    color: (map['color'] as String?) ?? 'gray',
    sortOrder: (map['sort_order'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );

  Category copyWith({
    String? id,
    String? name,
    String? color,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    SyncStatus? syncStatus,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  static String nameForId(String? id) {
    if (id == weightliftingId) return 'Weightlifting';
    if (id == powerliftingId)  return 'Powerlifting';
    if (id == runningId)       return 'Running';
    if (id == crossfitId)      return 'CrossFit';
    if (id == gymnasticsId)    return 'Gymnastics';
    if (id == otherId)         return 'Other';
    // Legacy
    if (id == runId)           return 'Run';
    if (id == wodId)           return 'WOD';
    if (id == customId)        return 'Custom';
    return 'Other';
  }

  /// Seeded on new installs only. Existing installs keep their categories.
  static List<Category> get presets {
    final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    return [
      Category(id: weightliftingId, name: 'Weightlifting', color: 'amber',  sortOrder: 0, createdAt: now, updatedAt: now),
      Category(id: powerliftingId,  name: 'Powerlifting',  color: 'red',    sortOrder: 1, createdAt: now, updatedAt: now),
      Category(id: runningId,       name: 'Running',       color: 'blue',   sortOrder: 2, createdAt: now, updatedAt: now),
      Category(id: crossfitId,      name: 'CrossFit',      color: 'green',  sortOrder: 3, createdAt: now, updatedAt: now),
      Category(id: gymnasticsId,    name: 'Gymnastics',    color: 'purple', sortOrder: 4, createdAt: now, updatedAt: now),
      Category(id: otherId,         name: 'Other',         color: 'gray',   sortOrder: 5, createdAt: now, updatedAt: now),
    ];
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd /Users/ida-eun/projects/peaklog && dart analyze lib/domain/models/category.dart 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/ida-eun/projects/peaklog
git add lib/domain/models/category.dart
git commit -m "feat: Category model — color field, 6 new presets, CategoryColor palette"
```

---

## Task 2: DB migration v12 → v13 (add color column)

**Files:**
- Modify: `lib/core/database/database_helper.dart`

- [ ] **Step 1: Change `version: 12` to `version: 13`**

Find (around line 21):
```dart
      version: 12,
```
Replace with:
```dart
      version: 13,
```

- [ ] **Step 2: Add `color` column to `_onCreate` categories table**

Find the `CREATE TABLE categories` statement in `_onCreate`:
```dart
    await db.execute('''
      CREATE TABLE categories (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
```

Replace with:
```dart
    await db.execute('''
      CREATE TABLE categories (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        color       TEXT NOT NULL DEFAULT 'gray',
        sort_order  INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
```

- [ ] **Step 3: Add v13 migration block at end of `_migrate()`**

After the `if (oldVersion < 12)` block, add:

```dart
    if (oldVersion < 13) {
      // Add color column; existing rows default to 'gray'.
      await _addColumnIfMissing(
          db, 'categories', 'color', "TEXT NOT NULL DEFAULT 'gray'");
      // Set correct colors for the legacy preset IDs that existing users have.
      await db.execute(
          "UPDATE categories SET color = 'amber' WHERE id = 'preset-category-weightlifting'");
      await db.execute(
          "UPDATE categories SET color = 'blue'  WHERE id = 'preset-category-run'");
      await db.execute(
          "UPDATE categories SET color = 'green' WHERE id = 'preset-category-wod'");
      // 'preset-category-custom' keeps 'gray' — already correct from the DEFAULT.
    }
```

- [ ] **Step 4: Verify analysis**

```bash
cd /Users/ida-eun/projects/peaklog && dart analyze lib/core/database/database_helper.dart 2>&1 | head -20
```

- [ ] **Step 5: Commit**

```bash
cd /Users/ida-eun/projects/peaklog
git add lib/core/database/database_helper.dart
git commit -m "feat: db v13 — add color column to categories, set preset defaults"
```

---

## Task 3: Home screen redesign

**Files:**
- Modify: `lib/features/home/home_screen.dart`

Design decisions enforced in this task:
- **Flat list only.** `ListView.separated` with no headers, no grouping. Category information lives in the colored dot on each row.
- **Chips are horizontally scrollable.** `ListView(scrollDirection: Axis.horizontal)` — no wrapping, handles unlimited categories.
- **PB display rule:** if `hasPb == true && bestValue != '—'` → amber trophy icon + bestValue text; if `hasPb == false && bestValue != '—'` → plain bestValue in `label2`; if `bestValue == '—'` → nothing shown before chevron.

Structural changes vs. current file:
- Remove `_dropdownOpen` state and `_buildDropdownPanel()`.
- Remove `_dateText()` (date no longer shown on home rows).
- Watch `categoriesProvider` to build chips and color lookup map.
- Replace `_ExerciseCard` with `_ExerciseRow`.
- Wrap each row in `SwipeableRow` (share → navigate to detail, delete → confirm then archive).
- `ListView.builder` → `ListView.separated`.

- [ ] **Step 1: Replace the file**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/utils/unit_converter.dart';
import '../../domain/models/category.dart';
import '../../domain/models/personal_best.dart';
import '../../providers/categories_provider.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../providers/records_provider.dart';
import '../../widgets/swipeable_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final FocusNode? searchFocus;
  const HomeScreen({super.key, this.searchFocus});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String _search = '';
  String? _filterCategoryId; // null = All
  late final FocusNode _searchFocus;
  late final bool _ownsFocusNode;

  void _onFocusChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    if (widget.searchFocus != null) {
      _searchFocus = widget.searchFocus!;
      _ownsFocusNode = false;
    } else {
      _searchFocus = FocusNode();
      _ownsFocusNode = true;
    }
    _searchFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onFocusChange);
    if (_ownsFocusNode) _searchFocus.dispose();
    super.dispose();
  }

  /// See "PB / PR Rendering Reference" in the plan for full type-by-type rules.
  String _bestValue(PersonalBest? pb, List<Record> records, Exercise exercise) {
    if (pb != null) {
      switch (exercise.recordType) {
        case RecordType.weight:
          if (pb.weight != null) {
            return UnitConverter.formatWeight(pb.weight!, exercise.baseUnit);
          }
        case RecordType.distance:
        case RecordType.forTime:
          if (pb.durationSeconds != null) {
            return UnitConverter.secondsToDisplay(pb.durationSeconds!);
          }
        case RecordType.amrap:
          if (pb.rounds != null) return '${pb.rounds} rounds';
        case null: break;
      }
    }
    if (records.isEmpty || exercise.recordType == null) return '—';
    final active = records.where((r) => !r.isDeleted).toList();
    if (active.isEmpty) return '—';
    switch (exercise.recordType!) {
      case RecordType.weight:
        final best = active.where((r) => r.weight != null)
            .fold<Record?>(null, (b, r) => b == null || r.weight! > b.weight! ? r : b);
        return best != null ? UnitConverter.formatWeight(best.weight!, exercise.baseUnit) : '—';
      case RecordType.distance:
      case RecordType.forTime:
        final best = active.where((r) => r.durationSeconds != null)
            .fold<Record?>(null, (b, r) => b == null || r.durationSeconds! < b.durationSeconds! ? r : b);
        return best != null ? UnitConverter.secondsToDisplay(best.durationSeconds!) : '—';
      case RecordType.amrap:
        final best = active.where((r) => r.rounds != null)
            .fold<Record?>(null, (b, r) => b == null || r.rounds! > b.rounds! ? r : b);
        return best != null ? '${best.rounds} rounds' : '—';
    }
  }

  Future<void> _confirmDelete(BuildContext context, Exercise exercise) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('"${exercise.displayName}" and all its records will be deleted.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(exercisesProvider.notifier).deleteExercise(exercise.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final exercises  = ref.watch(exercisesProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    // id → color key lookup; avoids repeated list scans inside itemBuilder.
    final colorMap = {for (final c in categories) c.id: c.color};

    final filtered = exercises.where((e) {
      final matchesSearch = _search.isEmpty ||
          e.displayName.toLowerCase().contains(_search.toLowerCase());
      final matchesCat = _filterCategoryId == null || e.categoryId == _filterCategoryId;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'PeakLog',
                      style: AppTypography.appTitle.copyWith(color: AppColors.label1),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: _IconButton(icon: AppIcons.person),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: _IconButton(icon: AppIcons.settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Search bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.separator, width: 0.5),
                ),
                child: TextField(
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _search = v),
                  cursorColor: AppColors.textPrimaryAlt,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.label1,
                  ),
                  decoration: InputDecoration(
                    hintText: _searchFocus.hasFocus ? null : 'Search exercises...',
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryAlt,
                    ),
                    prefixIcon: Icon(AppIcons.search, size: 16, color: AppColors.textSecondaryAlt),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Category chip filter (horizontally scrollable) ───────
            // Uses ListView so chips never wrap and always accommodate
            // any number of categories without overflow.
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All',
                    color: null,
                    selected: _filterCategoryId == null,
                    onTap: () => setState(() => _filterCategoryId = null),
                  ),
                  ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(
                      label: cat.name,
                      color: CategoryColor.toColor(cat.color),
                      selected: _filterCategoryId == cat.id,
                      onTap: () => setState(() => _filterCategoryId = cat.id),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Exercise list (flat, no section headers) ─────────────
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises',
                        style: TextStyle(color: AppColors.label2),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 34, // aligns with exercise name start
                          color: AppColors.separator,
                        ),
                        itemBuilder: (context, index) {
                          final exercise = filtered[index];
                          final records =
                              ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
                          final pb = ref.watch(personalBestProvider(exercise.id));
                          final bestValue = _bestValue(pb, records, exercise);
                          final catColor = exercise.categoryId != null
                              ? CategoryColor.toColor(colorMap[exercise.categoryId])
                              : AppColors.label2;

                          return SwipeableRow(
                            id: exercise.id,
                            onEdit: () => context.push('/exercise/${exercise.id}'),
                            onShare: () => context.push('/exercise/${exercise.id}'),
                            onDelete: () => _confirmDelete(context, exercise),
                            child: _ExerciseRow(
                              exercise: exercise,
                              bestValue: bestValue,
                              categoryColor: catColor,
                              hasPb: pb != null,
                            ),
                          );
                        },
                      ),
                    ),
            ),
            // ── Add Exercise button ──────────────────────────────────
            Container(
              color: AppColors.background,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: GestureDetector(
                    onTap: () => context.push('/add-exercise'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.actionDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.actionDarkBorder),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('+',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300)),
                            const SizedBox(width: 6),
                            Text('Add Exercise',
                                style: AppTypography.button.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.separator),
      ),
      child: Center(child: Icon(icon, size: 17, color: AppColors.textPrimaryAlt)),
    );
  }
}

/// Horizontal chip for the category filter bar.
/// `color: null` = the "All" chip (no dot).
class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipSelected : AppColors.chip,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.85) : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textPrimaryAlt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single exercise row. No date, no card border. Color dot on the left,
/// PB value + chevron on the right.
///
/// PB rendering rules (see plan for full table):
///   hasPb=true  + value!='—' → amber trophy icon + value
///   hasPb=false + value!='—' → plain value in label2 color
///   value=='—'               → nothing before chevron
class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final String bestValue;
  final Color categoryColor;
  final bool hasPb;

  const _ExerciseRow({
    required this.exercise,
    required this.bestValue,
    required this.categoryColor,
    required this.hasPb,
  });

  @override
  Widget build(BuildContext context) {
    final showValue = bestValue != '—';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Category color dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          // Exercise name
          Expanded(
            child: Text(
              exercise.displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.label1,
              ),
            ),
          ),
          // PB / best value
          if (showValue && hasPb) ...[
            Icon(AppIcons.trophy, size: 13, color: AppColors.pbGold),
            const SizedBox(width: 4),
            Text(
              bestValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.label1,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (showValue) ...[
            Text(
              bestValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.label2,
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Chevron
          Icon(AppIcons.forward, size: 18, color: AppColors.chevron),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

```bash
cd /Users/ida-eun/projects/peaklog && dart analyze lib/features/home/home_screen.dart 2>&1 | head -30
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/ida-eun/projects/peaklog
git add lib/features/home/home_screen.dart
git commit -m "feat: home screen — compact rows, chip filter, swipe actions, category dots"
```

---

## Task 4: Category management — color picker

**Files:**
- Modify: `lib/features/categories/category_management_screen.dart`

Changes:
- `_CategoryTile` gains a 10px colored dot in the leading slot.
- `_showAddDialog` / `_showEditDialog` replaced by `_showAddSheet` / `_showEditSheet` which open a `showModalBottomSheet` containing a `Wrap` color swatch picker.
- `_isPreset()` uses `id.startsWith('preset-category-')` to match all current and legacy preset IDs.
- `_reorder` uses `Category.copyWith()` instead of constructor.

- [ ] **Step 1: Replace the file**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/category.dart';
import '../../providers/categories_provider.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: categories.isEmpty
                ? const Center(
                    child: Text(
                      'No categories',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: categories.length,
                    onReorderItem: (oldIdx, newIdx) =>
                        _reorder(categories, oldIdx, newIdx),
                    proxyDecorator: (child, _, animation) => Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: child,
                    ),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      return _CategoryTile(
                        key: ValueKey(cat.id),
                        category: cat,
                        isPreset: _isPreset(cat.id),
                        onEdit: () => _showEditSheet(context, cat),
                        onDelete: () => _confirmDelete(context, cat),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Matches all current and legacy preset IDs ('preset-category-*').
  bool _isPreset(String id) => id.startsWith('preset-category-');

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.back, size: 18, color: AppColors.primary),
                        const SizedBox(width: 4),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryAlt,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddSheet(context),
                    child: const Text(
                      '+ Add',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.separatorAlt),
        ],
      ),
    );
  }

  Future<void> _reorder(List<Category> cats, int oldIdx, int newIdx) async {
    final reordered = List<Category>.from(cats);
    final moved = reordered.removeAt(oldIdx);
    reordered.insert(newIdx, moved);

    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < reordered.length; i++) {
      await DatabaseHelper.instance.updateCategory(
        reordered[i].copyWith(sortOrder: i, updatedAt: now),
      );
    }
    ref.invalidate(categoriesProvider);
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final result = await _openSheet(
      context,
      title: 'Add Category',
      initialName: '',
      initialColor: 'gray',
    );
    if (result == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final cat = Category(
      id: const Uuid().v4(),
      name: result.$1,
      color: result.$2,
      sortOrder: cats.length,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseHelper.instance.insertCategory(cat);
    ref.invalidate(categoriesProvider);
  }

  Future<void> _showEditSheet(BuildContext context, Category cat) async {
    final result = await _openSheet(
      context,
      title: 'Edit Category',
      initialName: cat.name,
      initialColor: cat.color,
    );
    if (result == null) return;

    await DatabaseHelper.instance.updateCategory(
      cat.copyWith(
        name: result.$1,
        color: result.$2,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    ref.invalidate(categoriesProvider);
  }

  /// Opens `_CategoryEditSheet` and returns `(name, colorKey)` or null.
  Future<(String, String)?> _openSheet(
    BuildContext context, {
    required String title,
    required String initialName,
    required String initialColor,
  }) {
    return showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryEditSheet(
        title: title,
        initialName: initialName,
        initialColor: initialColor,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category cat) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            '"${cat.name}" will be deleted. Exercises in this category will be uncategorized.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper.instance.deleteCategory(cat.id);
    ref.invalidate(categoriesProvider);
  }
}

// ── Bottom sheet (add / edit) ─────────────────────────────────────────────────

class _CategoryEditSheet extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialColor;

  const _CategoryEditSheet({
    required this.title,
    required this.initialName,
    required this.initialColor,
  });

  @override
  State<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<_CategoryEditSheet> {
  late final TextEditingController _ctrl;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryAlt,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimaryAlt),
            decoration: InputDecoration(
              hintText: 'Category name',
              hintStyle: const TextStyle(color: AppColors.textSecondaryAlt),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.separatorAlt),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.separatorAlt),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryAlt,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CategoryColor.palette.map((key) {
              final isSelected = key == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = key),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CategoryColor.toColor(key),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.textPrimaryAlt, width: 2.5)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          )]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.separatorAlt),
                    ),
                    child: const Center(
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryAlt)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _ctrl.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(
                          context, (_ctrl.text.trim(), _selectedColor)),
                  child: AnimatedOpacity(
                    opacity: _ctrl.text.trim().isEmpty ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.actionDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Save',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool isPreset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.isPreset,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separatorAlt),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.dragHandle, color: const Color(0xFFD1D5DA), size: 18),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: CategoryColor.toColor(category.color),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2328),
          ),
        ),
        subtitle: isPreset
            ? const Text('System',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryAlt))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(AppIcons.edit, size: 18, color: AppColors.textTertiary),
              ),
            ),
            if (!isPreset)
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(AppIcons.delete, size: 18, color: const Color(0xFFCF222E)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

```bash
cd /Users/ida-eun/projects/peaklog && dart analyze lib/features/categories/category_management_screen.dart 2>&1 | head -30
```

- [ ] **Step 3: Commit**

```bash
cd /Users/ida-eun/projects/peaklog
git add lib/features/categories/category_management_screen.dart
git commit -m "feat: category management — color picker in add/edit sheet, color dots on tiles"
```

---

## Task 5: Add exercise sheet — live categories with color dots

**Files:**
- Modify: `lib/features/home/add_exercise_sheet.dart`

Changes:
- Remove the static `_categories` constant.
- Watch `categoriesProvider` (falls back to `Category.presets` while loading).
- Update `_CategoryDropdown` to accept `List<Category>` instead of `List<(String, String)>`.
- Show 8px color dot in each dropdown row and in the collapsed summary.
- `_categoryLabel()` looks up from the live list.

- [ ] **Step 1: Remove the static `_categories` constant**

Find and delete these lines (around lines 49–54):
```dart
  static const _categories = [
    (Category.weightliftingId, 'Weightlifting'),
    (Category.runId,           'Run'),
    (Category.wodId,           'WOD'),
    (Category.customId,        'Custom'),
  ];
```

- [ ] **Step 2: Replace `_categoryLabel()` method**

Find:
```dart
  String _categoryLabel(String id) {
    for (final c in _categories) {
      if (c.$1 == id) return c.$2;
    }
    return 'Custom';
  }
```

Replace with:
```dart
  String _categoryLabel(String id, List<Category> categories) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => categories.isNotEmpty ? categories.first : Category.presets.first,
    ).name;
  }
```

- [ ] **Step 3: Add `categories` local variable at the top of `build()`**

Find the first line of `build()`:
```dart
    final nameEmpty = _nameCtrl.text.trim().isEmpty;
```

Insert before it:
```dart
    final categories = ref.watch(categoriesProvider).valueOrNull ?? Category.presets;
```

- [ ] **Step 4: Update the `_CategoryDropdown` call**

Find:
```dart
                  _CategoryDropdown(
                    selectedId: _selectedCategoryId,
                    categoryLabel: _selectedCategoryId != null
                        ? _categoryLabel(_selectedCategoryId!)
                        : null,
                    open: _categoryOpen,
                    categories: _categories,
                    onToggle: () =>
                        setState(() => _categoryOpen = !_categoryOpen),
                    onSelect: (id) => setState(() {
                      _selectedCategoryId = id;
                      _categoryOpen = false;
                    }),
                  ),
```

Replace with:
```dart
                  _CategoryDropdown(
                    selectedId: _selectedCategoryId,
                    categoryLabel: _selectedCategoryId != null
                        ? _categoryLabel(_selectedCategoryId!, categories)
                        : null,
                    open: _categoryOpen,
                    categories: categories,
                    onToggle: () =>
                        setState(() => _categoryOpen = !_categoryOpen),
                    onSelect: (id) => setState(() {
                      _selectedCategoryId = id;
                      _categoryOpen = false;
                    }),
                  ),
```

- [ ] **Step 5: Replace the `_CategoryDropdown` widget class**

Find the class declaration `class _CategoryDropdown extends StatelessWidget {` and replace the entire class with:

```dart
class _CategoryDropdown extends StatelessWidget {
  final String? selectedId;
  final String? categoryLabel;
  final bool open;
  final List<Category> categories;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  const _CategoryDropdown({
    required this.selectedId,
    required this.categoryLabel,
    required this.open,
    required this.categories,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCat = selectedId != null
        ? categories.where((c) => c.id == selectedId).firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryAlt,
                    ),
                  ),
                  if (!open && selectedCat != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CategoryColor.toColor(selectedCat.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categoryLabel ?? selectedCat.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryAlt,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    open ? AppIcons.caretUp : AppIcons.caretDown,
                    size: 16,
                    color: AppColors.textSecondaryAlt,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Column(
              children: categories.map((cat) {
                final isSelected = cat.id == selectedId;
                return GestureDetector(
                  onTap: () => onSelect(cat.id),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.separatorAlt)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: CategoryColor.toColor(cat.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.textPrimaryAlt
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(AppIcons.check, size: 14, color: AppColors.textPrimaryAlt),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Verify analysis — add_exercise_sheet only**

```bash
cd /Users/ida-eun/projects/peaklog && dart analyze lib/features/home/add_exercise_sheet.dart 2>&1 | head -30
```

- [ ] **Step 7: Full project analysis**

```bash
cd /Users/ida-eun/projects/peaklog && dart analyze lib/ 2>&1 | grep -E "^  error" | head -30
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
cd /Users/ida-eun/projects/peaklog
git add lib/features/home/add_exercise_sheet.dart
git commit -m "feat: add exercise sheet — live categories with color dots"
```

---

## Self-Review Checklist

### Spec coverage
- [x] Replace card layout with compact rows → Task 3 (`_ExerciseRow`)
- [x] Category color dot on each row → Task 3 (8px circle, from `colorMap`)
- [x] Trophy icon + PB value on right → Task 3 (hasPb path, amber trophy)
- [x] Chevron on right → Task 3
- [x] Thin dividers between rows → Task 3 (`ListView.separated`, `indent: 34`)
- [x] No section headers, flat list only → Task 3 (explicitly documented in code comments)
- [x] Category color field in DB → Task 2
- [x] 6 seeded presets with correct colors → Task 1 + Task 2
- [x] Legacy IDs kept for exercise.dart backward compat → Task 1
- [x] Existing installs: colors set via migration UPDATE → Task 2
- [x] Category chip filter → Task 3 (`_CategoryChip`)
- [x] Chips horizontally scrollable via `ListView` → Task 3 (handles unlimited categories)
- [x] Color dot on chips → Task 3
- [x] Color picker in category add/edit → Task 4 (`_CategoryEditSheet`)
- [x] Fixed 8-color palette → Task 1 (`CategoryColor.palette`)
- [x] Swipe Share + Delete → Task 3 (`SwipeableRow`)
- [x] Delete confirmation → Task 3 (`_confirmDelete`)
- [x] Keep search bar, profile, settings, add button → Task 3 (preserved)
- [x] Empty state "No exercises" → Task 3 (preserved)
- [x] Color dot in add exercise sheet category dropdown → Task 5
- [x] PB rendering documented for all 4 record types → "PB / PR Rendering Reference" section

### Known decisions
- **Share swipe** navigates to `/exercise/$id` (exercise detail has export/sharing). No dedicated per-exercise share route exists at home level.
- **`_effectiveCategoryId`** in `AddExerciseSheet` still falls back to `Category.weightliftingId`. Unchanged per spec intent.
- **Existing installs** do not receive the 6 new preset categories. Only colors are migrated for the 4 legacy presets.
