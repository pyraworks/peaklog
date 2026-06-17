# Figma UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update all screens to match Figma design — surgical delta-only changes; most screens already match.

**Architecture:** 9 existing files modified, 1 new file created. Back buttons gain text labels. ExerciseDetail history rows route to new EditRecordScreen. updateRecord data layer added to support editing. AddExercise promoted from sheet to GoRoute.

**Tech Stack:** Flutter 3.x, Riverpod, go_router, sqflite

---

## File Map

| Action | Path | What changes |
|--------|------|-------------|
| Modify | `lib/core/enums/record_type.dart` | rename `pbLabel` → `prPbLabel`; weight→'PR', others→'PB' |
| Modify | `lib/core/database/database_helper.dart` | add `updateRecord()` |
| Modify | `lib/domain/repositories/record_repository.dart` | add `update()` to interface |
| Modify | `lib/data/repositories/record_repository_impl.dart` | implement `update()` |
| Modify | `lib/providers/records_provider.dart` | add `updateRecord()` to notifier |
| Create | `lib/features/record_input/edit_record_screen.dart` | weight-only edit screen |
| Modify | `lib/app.dart` | add `/add-exercise` route; wire edit route to EditRecordScreen |
| Modify | `lib/features/home/home_screen.dart` | push '/add-exercise' instead of sheet |
| Modify | `lib/features/home/add_exercise_sheet.dart` | header: "← Home" text |
| Modify | `lib/features/exercise_detail/exercise_detail_screen.dart` | header text+category; remove compare; history→edit route |
| Modify | `lib/features/one_rm_table/one_rm_table_screen.dart` | header: add "Back" text |
| Modify | `lib/features/profile/profile_screen.dart` | header: "Home" text; remove SETTINGS section |
| Modify | `lib/features/settings/settings_screen.dart` | header text; remove ProfileCard; add PROFILE section; remove APP section |

---

## Task 1: prPbLabel — weight→'PR', others→'PB'

**Files:**
- Modify: `lib/core/enums/record_type.dart`

- [ ] **Step 1: Rename pbLabel → prPbLabel with per-type logic**

```dart
// lib/core/enums/record_type.dart
enum RecordType { weight, distance, forTime, amrap }

extension RecordTypeX on RecordType {
  bool get isTimeBased =>
      this == RecordType.distance || this == RecordType.forTime;

  String get prPbLabel {
    switch (this) {
      case RecordType.weight:   return 'PR';
      case RecordType.distance: return 'PB';
      case RecordType.forTime:  return 'PB';
      case RecordType.amrap:    return 'PB';
    }
  }

  String get inputLabel {
    switch (this) {
      case RecordType.weight:   return 'Weight';
      case RecordType.distance: return 'Distance';
      case RecordType.forTime:  return 'Time';
      case RecordType.amrap:    return 'Rounds';
    }
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/core/enums/record_type.dart
```
Expected: no errors.

---

## Task 2: updateRecord — data layer

**Files:**
- Modify: `lib/core/database/database_helper.dart` (after `softDeleteRecord`)
- Modify: `lib/domain/repositories/record_repository.dart`
- Modify: `lib/data/repositories/record_repository_impl.dart`
- Modify: `lib/providers/records_provider.dart`

- [ ] **Step 1: Add `updateRecord` to DatabaseHelper**

In `lib/core/database/database_helper.dart`, add after `softDeleteRecord()`:

```dart
Future<void> updateRecord(Record record) async {
  final db = await database;
  await db.update(
    'records',
    record.toMap(),
    where: 'id = ?',
    whereArgs: [record.id],
  );
}
```

- [ ] **Step 2: Add `update` to RecordRepository interface**

Replace the entire `lib/domain/repositories/record_repository.dart`:

```dart
import '../../core/models/record.dart';

abstract class RecordRepository {
  Future<List<Record>> getByExercise(String exerciseId);
  Future<Record> insert(Record record);
  Future<void> update(Record record);
  Future<void> softDelete(String id);
}
```

- [ ] **Step 3: Implement `update` in RecordRepositoryImpl**

Replace the entire `lib/data/repositories/record_repository_impl.dart`:

```dart
import '../../core/database/database_helper.dart';
import '../../core/models/record.dart';
import '../../domain/repositories/record_repository.dart';

class RecordRepositoryImpl implements RecordRepository {
  const RecordRepositoryImpl._();
  static const RecordRepositoryImpl instance = RecordRepositoryImpl._();

  @override
  Future<List<Record>> getByExercise(String exerciseId) =>
      DatabaseHelper.instance.getRecordsForExercise(exerciseId);

  @override
  Future<Record> insert(Record record) async {
    await DatabaseHelper.instance.insertRecord(record);
    return record;
  }

  @override
  Future<void> update(Record record) =>
      DatabaseHelper.instance.updateRecord(record);

  @override
  Future<void> softDelete(String id) =>
      DatabaseHelper.instance.softDeleteRecord(id);
}
```

- [ ] **Step 4: Add `updateRecord` to RecordsNotifier**

In `lib/providers/records_provider.dart`, add after `addRecord()`:

```dart
Future<void> updateRecord(Record record) async {
  await RecordRepositoryImpl.instance.update(record);
  final current = state.valueOrNull ?? [];
  state = AsyncData(
    current.map((r) => r.id == record.id ? record : r).toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt)),
  );
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/core/database/database_helper.dart lib/domain/repositories/record_repository.dart lib/data/repositories/record_repository_impl.dart lib/providers/records_provider.dart
```
Expected: no errors.

---

## Task 3: EditRecordScreen (new file)

**Files:**
- Create: `lib/features/record_input/edit_record_screen.dart`

- [ ] **Step 1: Create EditRecordScreen**

```dart
// lib/features/record_input/edit_record_screen.dart
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../../core/design/app_colors.dart';
import '../../core/models/record.dart';
import '../../providers/records_provider.dart';

class EditRecordScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final String recordId;
  const EditRecordScreen({
    required this.exerciseId,
    required this.recordId,
    super.key,
  });

  @override
  ConsumerState<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends ConsumerState<EditRecordScreen> {
  Record? _record;
  bool _loading = true;
  bool _saving = false;

  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final r = await DatabaseHelper.instance.getRecordById(widget.recordId);
    if (!mounted) return;
    if (r != null) {
      _weightCtrl.text = r.weight?.toString() ?? '';
      _repsCtrl.text = (r.reps ?? 1).toString();
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(r.performedAt);
    }
    setState(() {
      _record = r;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          _buildHeader(context),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_record == null)
            const Expanded(child: Center(child: Text('Record not found')))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DateCard(
                      selected: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                    ),
                    const SizedBox(height: 12),
                    _WeightRepsCard(
                      weightCtrl: _weightCtrl,
                      repsCtrl: _repsCtrl,
                    ),
                    const SizedBox(height: 24),
                    _SaveButton(
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: 16),
                    _DeleteButton(
                      onPressed: _saving ? null : _delete,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(CupertinoIcons.back,
                            size: 18, color: Color(0xFF3478F6)),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF3478F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit Record',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF24292E),
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE1E4E8)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final record = _record;
    if (record == null) return;
    final weight = double.tryParse(_weightCtrl.text.trim());
    final reps = max(1, int.tryParse(_repsCtrl.text.trim()) ?? 1);
    if (weight == null || weight <= 0) return;

    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = record.copyWith(
      weight: weight,
      reps: reps,
      performedAt: _selectedDate.millisecondsSinceEpoch,
      updatedAt: now,
    );
    await ref
        .read(recordsProvider(widget.exerciseId).notifier)
        .updateRecord(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Record'),
        content: const Text('This record will be permanently deleted.'),
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
    await ref
        .read(recordsProvider(widget.exerciseId).notifier)
        .deleteRecord(widget.recordId);
    if (!mounted) return;
    context.pop();
  }
}

// ── _DateCard ─────────────────────────────────────────────────────────────────

class _DateCard extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  const _DateCard({required this.selected, required this.onChanged});

  String get _label =>
      '${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E4E8)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.calendar,
                size: 16, color: Color(0xFF586069)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF24292E),
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_down,
                size: 12, color: Color(0xFF8C959F)),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    DateTime temp = selected;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 320,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF2F2F7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF586069))),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      onChanged(temp);
                      Navigator.pop(context);
                    },
                    child: const Text('Done',
                        style: TextStyle(
                            color: Color(0xFF3478F6),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selected,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2000),
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _WeightRepsCard ────────────────────────────────────────────────────────────

class _WeightRepsCard extends StatelessWidget {
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  const _WeightRepsCard({required this.weightCtrl, required this.repsCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E4E8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _InputField(
              controller: weightCtrl,
              label: 'WEIGHT',
              suffix: 'kg',
              decimal: true,
            ),
          ),
          Container(width: 1, height: 80, color: const Color(0xFFE1E4E8)),
          Expanded(
            child: _InputField(
              controller: repsCtrl,
              label: 'REPS',
              suffix: '회',
              decimal: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  const _InputField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.decimal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8C959F),
              letterSpacing: 0.64,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    TextInputType.numberWithOptions(decimal: decimal),
                inputFormatters: [
                  if (decimal)
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  else
                    FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF24292E),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.fromLTRB(16, 2, 8, 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                suffix,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8C959F),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── _SaveButton ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  const _SaveButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF24292E),
          border: Border.all(color: const Color(0xFF1B1F23)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: -0.15,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── _DeleteButton ─────────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.trash, size: 14, color: Color(0xFFCF2222)),
            SizedBox(width: 6),
            Text(
              'Delete Record',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFCF2222),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/record_input/edit_record_screen.dart
```
Expected: no errors.

---

## Task 4: Router — add routes

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Add import and routes**

In `lib/app.dart`, add import at top:

```dart
import 'features/record_input/edit_record_screen.dart';
```

Replace the two redirect routes:

```dart
// OLD — remove these two GoRoute blocks:
GoRoute(
  path: '/exercise/:id/add-record',
  redirect: (context, state) =>
      '/exercise/${state.pathParameters['id']}',
),
GoRoute(
  path: '/exercise/:id/record/:rid/edit',
  redirect: (context, state) =>
      '/exercise/${state.pathParameters['id']}',
),

// NEW — replace with:
GoRoute(
  path: '/exercise/:id/record/:rid/edit',
  builder: (context, state) {
    final exerciseId = state.pathParameters['id']!;
    final recordId = state.pathParameters['rid']!;
    return EditRecordScreen(
      exerciseId: exerciseId,
      recordId: recordId,
    );
  },
),
GoRoute(
  path: '/add-exercise',
  builder: (context, state) => const AddExerciseSheet(),
),
```

Also add import at top of `lib/app.dart`:
```dart
import 'features/home/add_exercise_sheet.dart';
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/app.dart
```
Expected: no errors.

---

## Task 5: HomeScreen — push route instead of sheet

**Files:**
- Modify: `lib/features/home/home_screen.dart`

- [ ] **Step 1: Change Add Exercise tap**

Find and replace the `onTap` inside the bottom bar's `GestureDetector`:

```dart
// OLD:
onTap: () => showAddExerciseSheet(context),

// NEW:
onTap: () => context.push('/add-exercise'),
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/home/home_screen.dart
```
Expected: no errors.

---

## Task 6: AddExerciseSheet header — "← Home" text

**Files:**
- Modify: `lib/features/home/add_exercise_sheet.dart`

- [ ] **Step 1: Update back button in header**

Find the `GestureDetector` wrapping `Icon(CupertinoIcons.back, ...)` in the header `Row`:

```dart
// OLD:
GestureDetector(
  onTap: () => Navigator.pop(context),
  child: const Icon(CupertinoIcons.back,
      color: Color(0xFF3478F6), size: 26),
),
const SizedBox(width: 8),

// NEW:
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => Navigator.pop(context),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(CupertinoIcons.back, size: 18, color: Color(0xFF3478F6)),
      SizedBox(width: 4),
      Text(
        'Home',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF3478F6),
        ),
      ),
    ],
  ),
),
const SizedBox(width: 12),
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/home/add_exercise_sheet.dart
```
Expected: no errors.

---

## Task 7: ExerciseDetailScreen — header + compare removal + history edit route

**Files:**
- Modify: `lib/features/exercise_detail/exercise_detail_screen.dart`

- [ ] **Step 1: Update `_Header` — "← Home" text + "name · category", remove Compare button**

Replace the entire `_Header` class:

```dart
class _Header extends StatelessWidget {
  final Exercise exercise;

  const _Header({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final categoryName = Category.nameForId(exercise.categoryId);
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: topPadding + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.pop(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.back,
                          size: 18, color: Color(0xFF3478F6)),
                      SizedBox(width: 4),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF3478F6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${exercise.displayName} · $categoryName',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF24292E),
                      letterSpacing: -0.17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE1E4E8)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Remove `records` param from `_Header` usage**

In `ExerciseDetailScreenState.build()`, the `_Header` widget is constructed as:
```dart
// OLD:
_Header(
  exercise: exercise,
  records: records,
),

// NEW:
_Header(exercise: exercise),
```

- [ ] **Step 3: Update history `onEdit` to push edit route**

In `ExerciseDetailScreenState.build()`, find the `_HistorySection` widget call.

Replace:
```dart
// OLD:
onEdit: (r) => showAddRecordSheet(context, ref, exercise,
    initialRecord: r),

// NEW:
onEdit: (r) => context.push(
    '/exercise/${widget.exerciseId}/record/${r.id}/edit'),
```

- [ ] **Step 4: Remove unused import (compare_screen.dart)**

In `lib/features/exercise_detail/exercise_detail_screen.dart`, delete the line:

```dart
import '../compare/compare_screen.dart';
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/features/exercise_detail/exercise_detail_screen.dart
```
Expected: no errors.

---

## Task 8: OneRMTableScreen — "← Back" text in header

**Files:**
- Modify: `lib/features/one_rm_table/one_rm_table_screen.dart`

- [ ] **Step 1: Update `_Header` back button**

Find in `_Header.build()` the `GestureDetector` wrapping `Icon(CupertinoIcons.back, ...)`:

```dart
// OLD:
GestureDetector(
  onTap: () => context.pop(),
  behavior: HitTestBehavior.opaque,
  child: const Padding(
    padding: EdgeInsets.only(right: 8),
    child: Icon(
      CupertinoIcons.back,
      color: Color(0xFF3478F6),
      size: 24,
    ),
  ),
),

// NEW:
GestureDetector(
  onTap: () => context.pop(),
  behavior: HitTestBehavior.opaque,
  child: const Padding(
    padding: EdgeInsets.only(right: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.back, size: 18, color: Color(0xFF3478F6)),
        SizedBox(width: 4),
        Text(
          'Back',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF3478F6),
          ),
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/one_rm_table/one_rm_table_screen.dart
```
Expected: no errors.

---

## Task 9: ProfileScreen — "← Home" text + remove SETTINGS section

**Files:**
- Modify: `lib/features/profile/profile_screen.dart`

- [ ] **Step 1: Update `_CustomHeader` back button**

Replace the `GestureDetector` block inside `_CustomHeader.build()`:

```dart
// OLD:
GestureDetector(
  onTap: onBack,
  child: const Icon(
    CupertinoIcons.back,
    color: Color(0xFF3478F6),
    size: 24,
  ),
),
const SizedBox(width: 8),

// NEW:
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: onBack,
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(CupertinoIcons.back, size: 18, color: Color(0xFF3478F6)),
      SizedBox(width: 4),
      Text(
        'Home',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF3478F6),
        ),
      ),
    ],
  ),
),
const SizedBox(width: 12),
```

- [ ] **Step 2: Remove SETTINGS section from ListView**

In `ProfileScreen.build()`, find and delete:

```dart
// Delete this entire block (SETTINGS section):
const SizedBox(height: 24),

// ── Settings ────────────────────────────────────────────
const Padding(
  padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
  child: Text(
    'SETTINGS',
    ...
  ),
),
_SettingsCard(context: context),
```

- [ ] **Step 3: Remove `_SettingsCard` class definition**

In `lib/features/profile/profile_screen.dart`, delete the entire `_SettingsCard` class (it is no longer referenced after Step 2).

Search for `class _SettingsCard` and delete from that line to its closing `}`.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/profile/profile_screen.dart
```
Expected: no errors.

---

## Task 10: SettingsScreen — restructure sections

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Update `_SettingsHeader` back button**

Replace the `GestureDetector` block inside `_SettingsHeader.build()`:

```dart
// OLD:
GestureDetector(
  onTap: onBack,
  child: const Icon(
    CupertinoIcons.back,
    color: Color(0xFF3478F6),
    size: 24,
  ),
),
const SizedBox(width: 8),

// NEW:
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: onBack,
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(CupertinoIcons.back, size: 18, color: Color(0xFF3478F6)),
      SizedBox(width: 4),
      Text(
        'Home',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF3478F6),
        ),
      ),
    ],
  ),
),
const SizedBox(width: 12),
```

- [ ] **Step 2: Restructure the ListView children in `SettingsScreen.build()`**

Replace the entire `ListView` `children:` list:

```dart
children: [
  // ── UNITS section ─────────────────────────────────────
  const _SectionLabel('UNITS'),
  _UnitsCard(settings: settings, ref: ref),
  const SizedBox(height: 24),

  // ── PREFERENCES section ───────────────────────────────
  const _SectionLabel('PREFERENCES'),
  _CardSection(
    items: [
      _CardItem(title: 'Categories', onTap: () => snackbar('Coming soon')),
      _CardItem(title: 'Units', onTap: () => snackbar('Coming soon')),
      _CardItem(title: 'Appearance', onTap: () => snackbar('Coming soon')),
    ],
  ),
  const SizedBox(height: 24),

  // ── PROFILE section ───────────────────────────────────
  const _SectionLabel('PROFILE'),
  _CardSection(
    items: [
      _CardItem(
        title: 'Public Records',
        onTap: () => context.push('/public-records'),
      ),
    ],
  ),
  const SizedBox(height: 24),

  // ── DATA section ──────────────────────────────────────
  const _SectionLabel('DATA'),
  _CardSection(
    items: [
      _CardItem(title: 'Backup & Sync', onTap: () => snackbar('Coming soon')),
      _CardItem(title: 'Export Data', onTap: () => snackbar('Coming soon')),
    ],
  ),
],
```

- [ ] **Step 3: Remove unused imports and `_ProfileCard` class**

In `lib/features/settings/settings_screen.dart`:

a) Delete the import for `health_sync_screen.dart` (no longer used after APP section removal):
```dart
// Delete this line:
import '../health/health_sync_screen.dart';
```

b) Delete the entire `_ProfileCard` class definition (no longer referenced in ListView after Step 2):
Search for `class _ProfileCard` and delete from that line to its closing `}` (~130 lines).

Also delete the `_VersionRow` class (was in APP section, now removed):
Search for `class _VersionRow` and delete from that line to its closing `}`.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/settings/settings_screen.dart
```
Expected: no errors (no unused imports).

---

## Task 11: Final verification

- [ ] **Step 1: Full analyze**

```bash
flutter analyze
```
Expected: 0 errors, warnings acceptable.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 3: Simulator build**

```bash
flutter build ios --simulator
```
Expected: `✓ Built build/ios/iphonesimulator/Runner.app`

- [ ] **Step 4: Commit**

```bash
git add lib/core/enums/record_type.dart \
  lib/core/database/database_helper.dart \
  lib/domain/repositories/record_repository.dart \
  lib/data/repositories/record_repository_impl.dart \
  lib/providers/records_provider.dart \
  lib/features/record_input/edit_record_screen.dart \
  lib/app.dart \
  lib/features/home/home_screen.dart \
  lib/features/home/add_exercise_sheet.dart \
  lib/features/exercise_detail/exercise_detail_screen.dart \
  lib/features/one_rm_table/one_rm_table_screen.dart \
  lib/features/profile/profile_screen.dart \
  lib/features/settings/settings_screen.dart

git commit -m "feat: Figma UI redesign — back button text, edit record screen, section restructure"
```
