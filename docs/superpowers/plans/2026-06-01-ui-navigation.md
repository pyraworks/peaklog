# UI / Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add left category drawer with filter, clean up 1RM picker (remove white box), and add a compare screen (latest vs previous PB).

**Architecture:** Three independent changes to the home flow. CategoryDrawer is a stateless widget that receives state from HomeScreen. CompareScreen reads from the existing recordsProvider. 1RM panel visual-only change — no data model touches.

**Tech Stack:** Flutter, Riverpod 2.x, CupertinoIcons, existing models from DB Foundation

---

## File Map

| Action | File |
|--------|------|
| Create | `lib/features/home/category_drawer.dart` |
| Modify | `lib/features/home/home_screen.dart` |
| Modify | `lib/features/home/one_rm_panel.dart` |
| Create | `lib/features/compare/compare_screen.dart` |
| Modify | `lib/features/exercise_detail/exercise_detail_screen.dart` |

---

### Task 1: 1RM Panel — remove white card box

**Files:** `lib/features/home/one_rm_panel.dart`

- [ ] Replace the outer `Container` wrapper (lines 54–end of build) with a `Padding`, and set `CupertinoPicker.backgroundColor` to `Colors.transparent`. The panel now blends into the screen background with no card border. Replace the `build` return from line 54 to match:

```dart
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '1RM 계산기',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                if (bestKg != null)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showTable(context, bestKg!, unit),
                    child: const Text(
                      '표로 보기',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: SizedBox(
              height: 130,
              child: CupertinoPicker(
                scrollController: _scrollController,
                itemExtent: 38,
                backgroundColor: Colors.transparent,
                selectionOverlay: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AppTheme.separator, width: 0.5),
                      bottom: BorderSide(
                          color: AppTheme.separator, width: 0.5),
                    ),
                  ),
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _percent = index + _kMinPercent);
                },
                children: List.generate(
                  _kMaxPercent - _kMinPercent + 1,
                  (i) {
                    final pct = i + _kMinPercent;
                    final wt = bestKg != null
                        ? UnitConverter.formatWeight(
                            bestKg * (pct / 100), unit)
                        : '—';
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            wt,
                            style: TextStyle(
                              color: bestKg != null
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
```

- [ ] Run `flutter analyze` — expect no errors.

- [ ] Commit:
```bash
git add lib/features/home/one_rm_panel.dart
git commit -m "fix: remove white card box from 1RM picker, transparent background"
```

---

### Task 2: Create CategoryDrawer

**Files:** Create `lib/features/home/category_drawer.dart`

- [ ] Create the file with this content:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import 'add_exercise_sheet.dart';

class CategoryDrawer extends StatelessWidget {
  final ExerciseCategory? selected;
  final List<Exercise> exercises;
  final ValueChanged<ExerciseCategory?> onCategorySelected;

  const CategoryDrawer({
    required this.selected,
    required this.exercises,
    required this.onCategorySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: const Text(
                'PBPR',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5),
              ),
            ),
            const Divider(
                height: 0.5, thickness: 0.5, color: AppTheme.separator),
            _DrawerTile(
              label: '전체',
              icon: CupertinoIcons.square_grid_2x2,
              count: exercises.length,
              selected: selected == null,
              onTap: () {
                onCategorySelected(null);
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '카테고리',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8),
              ),
            ),
            ...ExerciseCategory.values.map((cat) {
              final count =
                  exercises.where((e) => e.category == cat).length;
              return _DrawerTile(
                label: cat.label,
                icon: _iconFor(cat),
                count: count,
                selected: selected == cat,
                onTap: () {
                  onCategorySelected(cat);
                  Navigator.pop(context);
                },
              );
            }),
            const Spacer(),
            const Divider(
                height: 0.5, thickness: 0.5, color: AppTheme.separator),
            _DrawerTile(
              label: '운동 추가',
              icon: CupertinoIcons.plus_circle,
              count: null,
              selected: false,
              accent: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddExerciseScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ExerciseCategory cat) {
    switch (cat) {
      case ExerciseCategory.strength: return CupertinoIcons.bolt_fill;
      case ExerciseCategory.running:  return CupertinoIcons.arrow_right_circle_fill;
      case ExerciseCategory.workout:  return CupertinoIcons.timer_fill;
      case ExerciseCategory.custom:   return CupertinoIcons.star_fill;
    }
  }
}

class _DrawerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? count;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = (accent || selected) ? AppTheme.accent : AppTheme.textPrimary;
    return Material(
      color: selected
          ? AppTheme.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: AppTheme.accent.withValues(alpha: 0.05),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400),
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: TextStyle(
                      color: selected
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                      fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] Run `flutter analyze` — expect no errors.

---

### Task 3: Wire CategoryDrawer into HomeScreen

**Files:** `lib/features/home/home_screen.dart`

- [ ] Replace the entire file with:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/exercises_provider.dart';
import 'add_exercise_sheet.dart' show AddExerciseScreen;
import 'category_drawer.dart';
import 'exercise_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _editMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ExerciseCategory? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final allExercises = exercisesAsync.valueOrNull ?? [];
    final canAdd = allExercises.length < 6;

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: CategoryDrawer(
        selected: _filterCategory,
        exercises: allExercises,
        onCategorySelected: (cat) =>
            setState(() => _filterCategory = cat),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        leading: Builder(
          builder: (ctx) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            child: const Icon(
              CupertinoIcons.line_horizontal_3,
              color: AppTheme.textPrimary,
              size: 22,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PBPR',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            if (_filterCategory != null)
              Text(
                _filterCategory!.label,
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
          ],
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => setState(() => _editMode = !_editMode),
            child: Text(
              _editMode ? '완료' : '편집',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (exercises) {
                var filtered = exercises;
                if (_filterCategory != null) {
                  filtered = filtered
                      .where((e) => e.category == _filterCategory)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((e) => e.displayName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (exercises.isEmpty) {
                  return const _EmptyState();
                }
                if (filtered.isEmpty) {
                  return _EmptyFilterState(
                    category: _filterCategory,
                    onClear: () =>
                        setState(() => _filterCategory = null),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final isFirst = i == 0;
                    final isLast = i == filtered.length - 1;
                    return ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: isFirst
                            ? const Radius.circular(10)
                            : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(10)
                            : Radius.zero,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ExerciseCard(
                            exercise: filtered[i],
                            editMode: _editMode,
                          ),
                          if (!isLast)
                            const Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: AppTheme.separator,
                              indent: 16,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomToolbar(
        searchController: _searchController,
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        onAdd: canAdd
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddExerciseScreen()),
                )
            : null,
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onAdd;

  const _BottomToolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.separator, width: 0.5),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: '운동 검색',
                  hintStyle: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: Icon(CupertinoIcons.search,
                      color: AppTheme.textSecondary, size: 16),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: onAdd != null
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onAdd,
                    child: const Icon(CupertinoIcons.square_pencil,
                        color: AppTheme.accent, size: 26),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.heart,
              color: AppTheme.textSecondary, size: 40),
          SizedBox(height: 12),
          Text('운동을 추가해보세요',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          SizedBox(height: 8),
          Text('하단 연필 버튼을 눌러 추가하세요',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final ExerciseCategory? category;
  final VoidCallback onClear;

  const _EmptyFilterState(
      {required this.category, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${category?.label ?? ''} 운동 없음',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: onClear,
            child: const Text('전체 보기',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] Run `flutter analyze` — expect no errors.

- [ ] Commit:
```bash
git add lib/features/home/category_drawer.dart lib/features/home/home_screen.dart
git commit -m "feat: left category drawer with filter, hamburger menu button"
```

---

### Task 4: Create CompareScreen

**Files:** Create `lib/features/compare/compare_screen.dart`

- [ ] Create the file:

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';

class CompareScreen extends ConsumerWidget {
  final Exercise exercise;
  const CompareScreen({required this.exercise, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('${exercise.displayName} — 비교')),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          if (records.isEmpty)
            const Expanded(
              child: Center(
                child: Text('기록이 없습니다',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15)),
              ),
            )
          else
            Expanded(
              child: _CompareBody(
                  exercise: exercise,
                  records: records,
                  settings: settings),
            ),
        ],
      ),
    );
  }
}

class _CompareBody extends StatelessWidget {
  final Exercise exercise;
  final List<Record> records;
  final UnitSettings? settings;

  const _CompareBody({
    required this.exercise,
    required this.records,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    // records are sorted newest first
    final latest = records.first;
    final latestVal = _getValue(latest);
    final latestDate = _dateStr(latest.performedAt);

    final rest = records.skip(1).toList();
    final prevBestRecord = _getBest(rest);
    final prevVal = prevBestRecord != null ? _getValue(prevBestRecord) : null;
    final prevDate =
        prevBestRecord != null ? _dateStr(prevBestRecord.performedAt) : null;

    String? diffStr;
    Color diffColor = AppTheme.textSecondary;
    if (latestVal != null && prevVal != null) {
      final diff = latestVal - prevVal;
      final improved = exercise.category == ExerciseCategory.strength
          ? diff > 0
          : diff < 0;
      diffColor = improved
          ? const Color(0xFF34C759)
          : diff == 0
              ? AppTheme.textSecondary
              : const Color(0xFFFF3B30);
      diffStr = _formatDiff(diff);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('최근 기록',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text('이전 PB',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text('차이',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.separator),
                // Values row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Latest
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestVal != null
                                  ? _format(latestVal)
                                  : '—',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 4),
                            Text(latestDate,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      // Previous PB
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              prevVal != null ? _format(prevVal) : '—',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 4),
                            Text(prevDate ?? '—',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      // Diff
                      Expanded(
                        child: Text(
                          diffStr ?? '—',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: diffColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (records.length < 2) ...[
            const SizedBox(height: 24),
            const Text(
              '이전 기록이 없습니다.\n기록을 2개 이상 추가하면 비교할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  double? _getValue(Record r) {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        if (r.weight != null && (r.reps == null || r.reps == 1)) {
          return r.weight;
        }
        return null;
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return r.durationSeconds?.toDouble();
      case ExerciseCategory.custom:
        return r.weight;
    }
  }

  Record? _getBest(List<Record> records) {
    final valid = records.where((r) => _getValue(r) != null).toList();
    if (valid.isEmpty) return null;
    switch (exercise.category) {
      case ExerciseCategory.strength:
      case ExerciseCategory.custom:
        return valid.reduce((a, b) =>
            (_getValue(a) ?? 0) >= (_getValue(b) ?? 0) ? a : b);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return valid.reduce((a, b) =>
            (_getValue(a) ?? double.maxFinite) <=
                    (_getValue(b) ?? double.maxFinite)
                ? a
                : b);
    }
  }

  String _format(double value) {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(
            value, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(value.toInt());
      case ExerciseCategory.custom:
        return value.toStringAsFixed(1);
    }
  }

  String _formatDiff(double diff) {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatDiffWeight(
            diff, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.formatDiffTime(diff.toInt());
      case ExerciseCategory.custom:
        final sign = diff >= 0 ? '+' : '';
        return '$sign${diff.toStringAsFixed(1)}';
    }
  }

  String _dateStr(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }
}
```

- [ ] Run `flutter analyze` — expect no errors.

---

### Task 5: Add 비교 button in ExerciseDetailScreen

**Files:** `lib/features/exercise_detail/exercise_detail_screen.dart`

- [ ] Add the import at the top:
```dart
import '../compare/compare_screen.dart';
```

- [ ] In the AppBar `actions:` list, add a "비교" button before "기록 추가":
```dart
actions: [
  CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CompareScreen(exercise: exercise)),
    ),
    child: const Text(
      '비교',
      style: TextStyle(
          color: AppTheme.accent,
          fontSize: 15,
          fontWeight: FontWeight.w500),
    ),
  ),
  CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RecordInputScreen(exercise: exercise)),
    ),
    child: const Text(
      '기록 추가',
      style: TextStyle(
          color: AppTheme.accent,
          fontSize: 15,
          fontWeight: FontWeight.w500),
    ),
  ),
],
```

- [ ] Run `flutter analyze` — expect no errors.

- [ ] Commit:
```bash
git add lib/features/compare/compare_screen.dart lib/features/exercise_detail/exercise_detail_screen.dart
git commit -m "feat: compare screen (latest vs previous PB), accessible from exercise detail"
```

---

### Task 6: Final verify

- [ ] Run `flutter analyze` — confirm `No issues found`.

- [ ] Final commit if needed:
```bash
git add -A
git commit -m "feat: UI/Navigation — drawer filter, 1RM picker cleanup, compare screen"
```
