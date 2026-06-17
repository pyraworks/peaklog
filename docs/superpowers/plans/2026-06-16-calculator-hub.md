# Calculator Hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Profile shortcut with a Calculator Hub containing 1RM, Pace, and Plate calculators, polish the Uncategorized category row, and wire persistence via SharedPreferences.

**Architecture:** New `lib/features/calculators/` feature folder holds the hub screen plus three calculator screens, pure-logic helpers for Pace and Plate, and a SharedPreferences wrapper. Router gets new `/calculators/**` routes. `OneRMTableScreen` gains optional `directWeightKg` params so the hub can open it without an exercise context.

**Tech Stack:** Flutter/Dart, Riverpod (for inherited providers only — calculators use local StatefulWidget state), SharedPreferences (already in project), go_router (already in project), `dart:convert` for plate-counts JSON.

---

## File Map

**Create:**
- `lib/features/calculators/calculator_hub_screen.dart` — 3-card hub
- `lib/features/calculators/one_rm_calculator_screen.dart` — standalone 1RM screen with weight input
- `lib/features/calculators/pace_calculator_screen.dart` — bidirectional pace/time calculator
- `lib/features/calculators/plate_calculator_screen.dart` — bidirectional plate/weight calculator
- `lib/features/calculators/pace_calculator_logic.dart` — pure functions: pace↔time conversion, split generation
- `lib/features/calculators/plate_calculator_logic.dart` — pure functions: greedy plate solver, total weight
- `lib/features/calculators/calculator_prefs.dart` — SharedPreferences wrapper
- `test/features/calculators/pace_calculator_logic_test.dart`
- `test/features/calculators/plate_calculator_logic_test.dart`

**Modify:**
- `lib/core/design/app_icons.dart` — add `calculator` icon
- `lib/features/home/home_screen.dart` — swap Profile button → Calculator button
- `lib/app.dart` — add `/calculators`, `/calculators/1rm`, `/calculators/pace`, `/calculators/plate`, `/calculators/1rm-table` routes
- `lib/features/one_rm_table/one_rm_table_screen.dart` — add optional `directWeightKg`/`directWeightUnit` params
- `lib/features/categories/category_management_screen.dart` — Uncategorized drag handle polish

---

## Task 1: AppIcons — add calculator icon

**Files:**
- Modify: `lib/core/design/app_icons.dart`

- [ ] **Step 1: Add the icon**

Open `lib/core/design/app_icons.dart`. After `static IconData get chart`, add:

```dart
static IconData get calculator => Icons.calculate_outlined;
```

The full Content section becomes:

```dart
// Content
static IconData get search     => Icons.search;
static IconData get settings   => Icons.settings;
static IconData get person     => Icons.person;
static IconData get calculator => Icons.calculate_outlined;
static IconData get trophy     => Icons.emoji_events;
static IconData get chart      => Icons.bar_chart;
static IconData get calendar   => Icons.calendar_today;
static IconData get qrCode     => Icons.qr_code;
static IconData get dragHandle => Icons.drag_handle;
static IconData get medal      => Icons.workspace_premium;
static IconData get image      => Icons.image;
static IconData get video      => Icons.videocam;
```

- [ ] **Step 2: Verify no analyzer errors**

Run: `cd /Users/ida-eun/projects/peaklog && flutter analyze lib/core/design/app_icons.dart`

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/design/app_icons.dart
git commit -m "feat: add calculator icon to AppIcons"
```

---

## Task 2: Pace calculator logic + tests (TDD)

**Files:**
- Create: `lib/features/calculators/pace_calculator_logic.dart`
- Create: `test/features/calculators/pace_calculator_logic_test.dart`

- [ ] **Step 1: Write the failing tests first**

Create `test/features/calculators/pace_calculator_logic_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/features/calculators/pace_calculator_logic.dart';

void main() {
  group('paceSecondsPerKm', () {
    test('5km in 20 min → 240 sec/km', () {
      expect(
        PaceCalculatorLogic.paceSecondsPerKm(distanceKm: 5.0, totalSeconds: 1200),
        closeTo(240.0, 0.01),
      );
    });
    test('zero distance returns null', () {
      expect(PaceCalculatorLogic.paceSecondsPerKm(distanceKm: 0, totalSeconds: 600), isNull);
    });
    test('zero time returns null', () {
      expect(PaceCalculatorLogic.paceSecondsPerKm(distanceKm: 5.0, totalSeconds: 0), isNull);
    });
  });

  group('totalSeconds', () {
    test('5km at 4:00/km → 20 min (1200s)', () {
      expect(
        PaceCalculatorLogic.totalSeconds(distanceKm: 5.0, paceSecondsPerKm: 240.0),
        1200,
      );
    });
    test('zero pace returns null', () {
      expect(PaceCalculatorLogic.totalSeconds(distanceKm: 5.0, paceSecondsPerKm: 0), isNull);
    });
  });

  group('formatPace', () {
    test('240 sec/km → "4:00"', () {
      expect(PaceCalculatorLogic.formatPace(240.0), '4:00');
    });
    test('270 sec/km → "4:30"', () {
      expect(PaceCalculatorLogic.formatPace(270.0), '4:30');
    });
    test('24 sec/km → "0:24"', () {
      expect(PaceCalculatorLogic.formatPace(24.0), '0:24');
    });
  });

  group('formatTime', () {
    test('1200s → "20:00"', () {
      expect(PaceCalculatorLogic.formatTime(1200), '20:00');
    });
    test('24s → "0:24"', () {
      expect(PaceCalculatorLogic.formatTime(24), '0:24');
    });
    test('3661s → "1:01:01"', () {
      expect(PaceCalculatorLogic.formatTime(3661), '1:01:01');
    });
  });

  group('parseTimeOrPace', () {
    test('"20:00" → 1200', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('20:00'), 1200);
    });
    test('"4:00" → 240', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('4:00'), 240);
    });
    test('"1:00:00" → 3600', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('1:00:00'), 3600);
    });
    test('invalid "abc" → null', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('abc'), isNull);
    });
    test('invalid seconds "4:60" → null', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('4:60'), isNull);
    });
  });

  group('generateSplits — 5km at 4:00/km', () {
    late List<(String, int)> splits;
    setUp(() {
      splits = PaceCalculatorLogic.generateSplits(5.0, 240.0);
    });
    test('has 14 splits total', () {
      expect(splits.length, 14); // 9 × 100m + 5 × km
    });
    test('first split is 100m = 24s', () {
      expect(splits.first, ('100m', 24));
    });
    test('last split is 5km = 1200s', () {
      expect(splits.last, ('5km', 1200));
    });
    test('1km split = 240s', () {
      final km1 = splits.firstWhere((s) => s.$1 == '1km');
      expect(km1.$2, 240);
    });
  });

  group('generateSplits — half marathon at 5:00/km', () {
    late List<(String, int)> splits;
    setUp(() {
      splits = PaceCalculatorLogic.generateSplits(
          PaceCalculatorLogic.halfMarathonKm, 300.0);
    });
    test('last split label is "21.1km Finish"', () {
      expect(splits.last.$1, '21.1km Finish');
    });
    test('last split time = halfMarathonKm * 300 seconds', () {
      expect(splits.last.$2,
          (PaceCalculatorLogic.halfMarathonKm * 300.0).round());
    });
  });

  group('generateSplits — marathon at 5:00/km', () {
    test('last split label is "42.195km Finish"', () {
      final splits = PaceCalculatorLogic.generateSplits(
          PaceCalculatorLogic.marathonKm, 300.0);
      expect(splits.last.$1, '42.195km Finish');
    });
  });

  group('generateSplits — empty when invalid', () {
    test('returns empty for zero distance', () {
      expect(PaceCalculatorLogic.generateSplits(0, 240), isEmpty);
    });
    test('returns empty for zero pace', () {
      expect(PaceCalculatorLogic.generateSplits(5.0, 0), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm failure**

```bash
cd /Users/ida-eun/projects/peaklog && flutter test test/features/calculators/pace_calculator_logic_test.dart
```

Expected: compilation error (`pace_calculator_logic.dart` not found yet).

- [ ] **Step 3: Implement the logic**

Create `lib/features/calculators/pace_calculator_logic.dart`:

```dart
class PaceCalculatorLogic {
  static const double halfMarathonKm = 21.0975;
  static const double marathonKm = 42.195;

  static double? paceSecondsPerKm({
    required double distanceKm,
    required int totalSeconds,
  }) {
    if (distanceKm <= 0 || totalSeconds <= 0) return null;
    return totalSeconds / distanceKm;
  }

  static int? totalSeconds({
    required double distanceKm,
    required double paceSecondsPerKm,
  }) {
    if (distanceKm <= 0 || paceSecondsPerKm <= 0) return null;
    return (distanceKm * paceSecondsPerKm).round();
  }

  // Formats seconds-per-km as "M:SS" — no leading zero on minutes.
  static String formatPace(double secondsPerKm) {
    final total = secondsPerKm.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // Formats total seconds as "M:SS" or "H:MM:SS" — no leading zero on first unit.
  static String formatTime(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
    return '$m:$ss';
  }

  // Parses "M:SS" or "H:MM:SS" → total seconds. Returns null on invalid input.
  static int? parseTimeOrPace(String text) {
    final parts = text.trim().split(':');
    if (parts.length == 2) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      if (a == null || b == null || b < 0 || b >= 60) return null;
      return a * 60 + b;
    }
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h == null || m == null || s == null) return null;
      if (m < 0 || m >= 60 || s < 0 || s >= 60) return null;
      return h * 3600 + m * 60 + s;
    }
    return null;
  }

  // Returns [(label, cumulativeSeconds)].
  // Layout: 100m..900m, then 1km..Nkm, then optional fractional finish.
  static List<(String, int)> generateSplits(
    double distanceKm,
    double paceSecPerKm,
  ) {
    if (distanceKm <= 0 || paceSecPerKm <= 0) return [];
    final result = <(String, int)>[];

    // 100m increments: cap at 900m (or distanceKm if < 1km)
    final cap = distanceKm < 1.0 ? distanceKm : 0.9;
    for (int i = 1; i * 0.1 <= cap + 1e-9; i++) {
      final d = i * 0.1;
      result.add(('${i * 100}m', (d * paceSecPerKm).round()));
    }

    // Whole km checkpoints: 1km … floor(distanceKm)km
    final fullKm = distanceKm.truncate();
    for (int km = 1; km <= fullKm; km++) {
      result.add(('${km}km', (km.toDouble() * paceSecPerKm).round()));
    }

    // Fractional finish for half/marathon/custom (only when distance >= 1km)
    final frac = distanceKm - fullKm;
    if (frac > 1e-6 && distanceKm >= 1.0) {
      result.add((_finishLabel(distanceKm), (distanceKm * paceSecPerKm).round()));
    }

    return result;
  }

  static String _finishLabel(double km) {
    if ((km - halfMarathonKm).abs() < 0.01) return '21.1km Finish';
    if ((km - marathonKm).abs() < 0.01) return '42.195km Finish';
    return '${km.toStringAsFixed(1)}km Finish';
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/calculators/pace_calculator_logic_test.dart
```

Expected: All 17 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/calculators/pace_calculator_logic.dart \
        test/features/calculators/pace_calculator_logic_test.dart
git commit -m "feat: pace calculator logic with split generation"
```

---

## Task 3: Plate calculator logic + tests (TDD)

**Files:**
- Create: `lib/features/calculators/plate_calculator_logic.dart`
- Create: `test/features/calculators/plate_calculator_logic_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/features/calculators/plate_calculator_logic_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/features/calculators/plate_calculator_logic.dart';

void main() {
  group('computeTotal', () {
    test('bar only (no plates)', () {
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: {},
      );
      expect(total, closeTo(20.0, 0.001));
    });
    test('20kg bar + 25×2 + 15×2 = 100kg', () {
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: {25.0: 2, 15.0: 2},
      );
      expect(total, closeTo(100.0, 0.001));
    });
    test('counts of zero contribute nothing', () {
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: {25.0: 0, 10.0: 0},
      );
      expect(total, closeTo(20.0, 0.001));
    });
  });

  group('solvePlates kg', () {
    test('100kg target → 25×2 + 15×2', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 100.0,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      expect(counts[25.0], 2);
      expect(counts[15.0], 2);
      expect(counts[20.0] ?? 0, 0);
    });
    test('all counts are even', () {
      for (final target in [60.0, 80.0, 100.0, 120.0, 140.0]) {
        final counts = PlateCalculatorLogic.solvePlates(
          totalWeightTarget: target,
          barWeight: 20.0,
          plateSizes: PlateCalculatorLogic.kgPlates,
        );
        for (final count in counts.values) {
          expect(count % 2, 0, reason: 'count $count for target $target is odd');
        }
      }
    });
    test('target equals bar weight → all zeros', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 20.0,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      expect(counts.values.every((v) => v == 0), isTrue);
    });
    test('target less than bar → all zeros', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 15.0,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      expect(counts.values.every((v) => v == 0), isTrue);
    });
    test('round-trip: solvePlates then computeTotal gives back target', () {
      const target = 100.0;
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: target,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: counts,
      );
      expect(total, closeTo(target, 0.01));
    });
  });

  group('solvePlates lb', () {
    test('225lb target with 45lb bar → 45×4', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 225.0,
        barWeight: 45.0,
        plateSizes: PlateCalculatorLogic.lbPlates,
      );
      expect(counts[45.0], 4); // 2 per side
    });
    test('135lb target with 45lb bar → 45×2', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 135.0,
        barWeight: 45.0,
        plateSizes: PlateCalculatorLogic.lbPlates,
      );
      expect(counts[45.0], 2);
    });
  });
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
flutter test test/features/calculators/plate_calculator_logic_test.dart
```

Expected: compilation error.

- [ ] **Step 3: Implement the logic**

Create `lib/features/calculators/plate_calculator_logic.dart`:

```dart
class PlateCalculatorLogic {
  static const kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  static const lbPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];
  static const kgBars = [20.0, 15.0, 10.0];
  static const lbBars = [45.0, 35.0];

  // Total weight = bar + sum(plateWeight × count) for all plates.
  // Counts are total plates (both sides): count=2 means 1 plate per side.
  static double computeTotal({
    required double barWeight,
    required Map<double, int> plateCounts,
  }) {
    var total = barWeight;
    for (final entry in plateCounts.entries) {
      total += entry.key * entry.value;
    }
    return total;
  }

  // Greedy minimum-plates solver.
  // Returns a map of plateSize → total count (always even: 0, 2, 4, …).
  // Plates not in [plateSizes] are not included in the result.
  static Map<double, int> solvePlates({
    required double totalWeightTarget,
    required double barWeight,
    required List<double> plateSizes,
  }) {
    final counts = <double, int>{for (final p in plateSizes) p: 0};
    var remaining = totalWeightTarget - barWeight;

    if (remaining <= 0) return counts;

    // Each pair = 1 plate per side = 2 × plateWeight total.
    for (final plate in plateSizes) {
      final pairs = (remaining / (plate * 2)).floor();
      if (pairs > 0) {
        counts[plate] = pairs * 2;
        remaining -= pairs * 2 * plate;
      }
    }

    return counts;
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/calculators/plate_calculator_logic_test.dart
```

Expected: All 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/calculators/plate_calculator_logic.dart \
        test/features/calculators/plate_calculator_logic_test.dart
git commit -m "feat: plate calculator logic with greedy solver"
```

---

## Task 4: Calculator persistence wrapper

**Files:**
- Create: `lib/features/calculators/calculator_prefs.dart`

- [ ] **Step 1: Create the file**

Create `lib/features/calculators/calculator_prefs.dart`:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorPrefs {
  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  // ── Last screen ─────────────────────────────────────────────────────────────
  static Future<String> getLastScreen() async =>
      (await _p).getString('calc_last_screen') ?? '';
  static Future<void> setLastScreen(String v) async =>
      (await _p).setString('calc_last_screen', v);

  // ── 1RM ─────────────────────────────────────────────────────────────────────
  static Future<double> get1rmWeight() async =>
      (await _p).getDouble('calc_1rm_weight') ?? 100.0;
  static Future<void> set1rmWeight(double v) async =>
      (await _p).setDouble('calc_1rm_weight', v);
  static Future<String> get1rmUnit() async =>
      (await _p).getString('calc_1rm_unit') ?? 'kg';
  static Future<void> set1rmUnit(String v) async =>
      (await _p).setString('calc_1rm_unit', v);

  // ── Pace ─────────────────────────────────────────────────────────────────────
  static Future<String> getPacePreset() async =>
      (await _p).getString('calc_pace_preset') ?? '5km';
  static Future<void> setPacePreset(String v) async =>
      (await _p).setString('calc_pace_preset', v);
  static Future<double> getPaceDistanceKm() async =>
      (await _p).getDouble('calc_pace_dist_km') ?? 5.0;
  static Future<void> setPaceDistanceKm(double v) async =>
      (await _p).setDouble('calc_pace_dist_km', v);
  static Future<String> getPaceTimeText() async =>
      (await _p).getString('calc_pace_time') ?? '';
  static Future<void> setPaceTimeText(String v) async =>
      (await _p).setString('calc_pace_time', v);
  static Future<String> getPacePaceText() async =>
      (await _p).getString('calc_pace_pace') ?? '';
  static Future<void> setPacePaceText(String v) async =>
      (await _p).setString('calc_pace_pace', v);
  static Future<String> getPaceLastEdited() async =>
      (await _p).getString('calc_pace_last_edited') ?? '';
  static Future<void> setPaceLastEdited(String v) async =>
      (await _p).setString('calc_pace_last_edited', v);

  // ── Plate ────────────────────────────────────────────────────────────────────
  static Future<String> getPlateUnit() async =>
      (await _p).getString('calc_plate_unit') ?? 'kg';
  static Future<void> setPlateUnit(String v) async =>
      (await _p).setString('calc_plate_unit', v);
  static Future<double> getPlateBarWeight() async =>
      (await _p).getDouble('calc_plate_bar') ?? 20.0;
  static Future<void> setPlateBarWeight(double v) async =>
      (await _p).setDouble('calc_plate_bar', v);
  static Future<double> getPlateTotalWeight() async =>
      (await _p).getDouble('calc_plate_total') ?? 60.0;
  static Future<void> setPlateTotalWeight(double v) async =>
      (await _p).setDouble('calc_plate_total', v);
  static Future<Map<double, int>> getPlateCounts(String unit) async {
    final raw = (await _p).getString('calc_plate_counts_$unit') ?? '{}';
    return _decodeCounts(raw);
  }
  static Future<void> setPlateCounts(String unit, Map<double, int> counts) async =>
      (await _p).setString('calc_plate_counts_$unit', _encodeCounts(counts));

  static Map<double, int> _decodeCounts(String json) {
    try {
      final raw = jsonDecode(json) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(double.parse(k), (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static String _encodeCounts(Map<double, int> counts) =>
      jsonEncode(counts.map((k, v) => MapEntry(k.toString(), v)));
}
```

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze lib/features/calculators/calculator_prefs.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/calculators/calculator_prefs.dart
git commit -m "feat: calculator SharedPreferences wrapper"
```

---

## Task 5: Modify OneRMTableScreen to support direct weight

**Files:**
- Modify: `lib/features/one_rm_table/one_rm_table_screen.dart`

- [ ] **Step 1: Add optional params and conditional build path**

Replace the class declaration and build method. The full updated file:

```dart
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_typography.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../widgets/screen_header.dart';

class OneRMTableScreen extends ConsumerWidget {
  final String? exerciseId;
  final double? directWeightKg;
  final String? directWeightUnit;

  const OneRMTableScreen({
    this.exerciseId,
    this.directWeightKg,
    this.directWeightUnit,
    super.key,
  }) : assert(
          exerciseId != null || directWeightKg != null,
          'Either exerciseId or directWeightKg must be provided',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double? pbKg = directWeightKg;
    String weightUnit = directWeightUnit ?? 'kg';
    String title = '1RM Table';

    if (exerciseId != null) {
      final pb = ref.watch(personalBestProvider(exerciseId!));
      final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
      final exercise =
          exercises.where((e) => e.id == exerciseId).firstOrNull;
      weightUnit = exercise?.baseUnit ?? 'kg';
      title = exercise != null
          ? '${exercise.displayName} — 1RM Table'
          : '1RM Table';
      pbKg = pb?.weight;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(backLabel: 'Back', title: title),
          Expanded(
            child: pbKg == null
                ? const Center(
                    child: Text(
                      '1RM 기록이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E7781),
                      ),
                    ),
                  )
                : _TableBody(pbKg: pbKg, weightUnit: weightUnit),
          ),
        ],
      ),
    );
  }
}

// ── _TableBody, _RowDivider, _PairRow, _Cell, _HundredRow remain identical ──
// (copy the existing private widget code below unchanged)

class _TableBody extends StatelessWidget {
  final double pbKg;
  final String weightUnit;
  const _TableBody({required this.pbKg, required this.weightUnit});

  String _fmt(int pct) =>
      UnitConverter.formatWeight(pbKg * pct / 100, weightUnit);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.separator, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(children: _buildRows()),
        ),
      ],
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];

    for (int left = 120; left >= 102; left -= 2) {
      if (rows.isNotEmpty) rows.add(const _RowDivider());
      rows.add(_PairRow(
        leftPct: left, leftValue: _fmt(left),
        rightPct: left - 1, rightValue: _fmt(left - 1),
      ));
    }

    rows.add(const _RowDivider());
    rows.add(_HundredRow(pbValue: _fmt(100)));

    for (int left = 99; left >= 51; left -= 2) {
      rows.add(const _RowDivider());
      rows.add(_PairRow(
        leftPct: left, leftValue: _fmt(left),
        rightPct: left - 1, rightValue: _fmt(left - 1),
      ));
    }

    return rows;
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 0, thickness: 0.5, color: AppColors.separator);
  }
}

class _PairRow extends StatelessWidget {
  final int leftPct;
  final String leftValue;
  final int rightPct;
  final String rightValue;
  const _PairRow({
    required this.leftPct,
    required this.leftValue,
    required this.rightPct,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(child: _Cell(pct: leftPct, value: leftValue)),
          Container(width: 0.5, color: AppColors.separator),
          Expanded(child: _Cell(pct: rightPct, value: rightValue)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int pct;
  final String value;
  const _Cell({required this.pct, required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: AppTypography.tablePct.copyWith(
                color: const Color(0xFF6E7781),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 68,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.tableCell.copyWith(
                color: AppColors.label1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HundredRow extends StatelessWidget {
  final String pbValue;
  const _HundredRow({required this.pbValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          Container(color: const Color(0xFFF8F9FA)),
          Row(
            children: [
              Expanded(child: _Cell(pct: 100, value: pbValue)),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'Current 1RM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB8860B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Center(
            child: Text(
              '—',
              style: TextStyle(fontSize: 12, color: AppColors.separator),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/one_rm_table/one_rm_table_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/one_rm_table/one_rm_table_screen.dart
git commit -m "feat: OneRMTableScreen accepts direct weight for calculator hub"
```

---

## Task 6: Calculator Hub screen

**Files:**
- Create: `lib/features/calculators/calculator_hub_screen.dart`

- [ ] **Step 1: Create the hub screen**

Create `lib/features/calculators/calculator_hub_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';

class CalculatorHubScreen extends StatelessWidget {
  const CalculatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(backLabel: 'Home', title: 'Calculators'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s24,
              ),
              children: [
                _CalculatorCard(
                  emoji: '🏋️',
                  title: '1RM Calculator',
                  description: 'Estimate your one-rep max and training percentages.',
                  onTap: () {
                    CalculatorPrefs.setLastScreen('1rm');
                    context.push('/calculators/1rm');
                  },
                ),
                const SizedBox(height: AppSpacing.s12),
                _CalculatorCard(
                  emoji: '🏃',
                  title: 'Pace Calculator',
                  description: 'Calculate pace, finish time, and race splits.',
                  onTap: () {
                    CalculatorPrefs.setLastScreen('pace');
                    context.push('/calculators/pace');
                  },
                ),
                const SizedBox(height: AppSpacing.s12),
                _CalculatorCard(
                  emoji: '⚫',
                  title: 'Plate Calculator',
                  description: 'Calculate barbell loading and total weight.',
                  onTap: () {
                    CalculatorPrefs.setLastScreen('plate');
                    context.push('/calculators/plate');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.separator, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.label1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.label2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.forward, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/calculators/calculator_hub_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/calculators/calculator_hub_screen.dart
git commit -m "feat: calculator hub screen with 3 cards"
```

---

## Task 7: Standalone 1RM Calculator screen

**Files:**
- Create: `lib/features/calculators/one_rm_calculator_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/calculators/one_rm_calculator_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/utils/unit_converter.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';

class OneRmCalculatorScreen extends StatefulWidget {
  const OneRmCalculatorScreen({super.key});

  @override
  State<OneRmCalculatorScreen> createState() => _OneRmCalculatorScreenState();
}

class _OneRmCalculatorScreenState extends State<OneRmCalculatorScreen> {
  static const _quickPcts = [70, 75, 80, 85, 90, 95];

  final _weightCtrl = TextEditingController();
  final _pctCtrl = TextEditingController(text: '85');
  String _unit = 'kg';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final weight = await CalculatorPrefs.get1rmWeight();
    final unit = await CalculatorPrefs.get1rmUnit();
    if (!mounted) return;
    setState(() {
      _weightCtrl.text = _fmtInput(weight);
      _unit = unit;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  String _fmtInput(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? v.toInt().toString() : s;
  }

  double? get _weightKg {
    final raw = double.tryParse(_weightCtrl.text.trim());
    if (raw == null || raw <= 0) return null;
    return _unit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
  }

  double? get _parsedPct {
    final v = double.tryParse(_pctCtrl.text.trim());
    if (v == null || v <= 0 || v > 200) return null;
    return v;
  }

  int? get _activeChip {
    final pct = _parsedPct;
    if (pct == null) return null;
    for (final q in _quickPcts) {
      if ((pct - q).abs() < 0.001) return q;
    }
    return null;
  }

  String _formatResult(double kg) {
    if (_unit == 'lbs') return UnitConverter.formatWeight(kg, 'lbs');
    final rounded = (kg * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? '${rounded.toInt()} kg'
        : '${rounded.toStringAsFixed(1)} kg';
  }

  void _tapChip(int pct) {
    _pctCtrl.text = '$pct';
    _pctCtrl.selection =
        TextSelection.collapsed(offset: _pctCtrl.text.length);
    setState(() {});
  }

  void _saveAndNavigateTable() {
    final wKg = _weightKg;
    if (wKg == null) return;
    CalculatorPrefs.set1rmWeight(
        _unit == 'lbs'
            ? UnitConverter.kgToLbs(wKg)
            : wKg);
    CalculatorPrefs.set1rmUnit(_unit);
    context.push(
      '/calculators/1rm-table',
      extra: {'weight': wKg, 'unit': _unit == 'lbs' ? 'lbs' : 'kg'},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final wKg = _weightKg;
    final pct = _parsedPct;
    final resultKg = (wKg != null && pct != null) ? wKg * pct / 100 : null;
    final resultDisplay = resultKg != null ? _formatResult(resultKg) : '—';
    final activeChip = _activeChip;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const ScreenHeader(backLabel: 'Calculators', title: '1RM Calculator'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s24,
                ),
                children: [
                  // ── Weight input card ────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border.all(color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1RM WEIGHT',
                          style: AppTypography.sectionLabel
                              .copyWith(color: AppColors.label2),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: AppTypography.inputValue.copyWith(
                                  color: AppColors.label1,
                                ),
                                cursorColor: AppColors.label1,
                                decoration: InputDecoration(
                                  hintText: '100',
                                  hintStyle: AppTypography.inputValue.copyWith(
                                    color: AppColors.label2,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) {
                                  setState(() {});
                                  final w = double.tryParse(
                                      _weightCtrl.text.trim());
                                  if (w != null) {
                                    CalculatorPrefs.set1rmWeight(w);
                                    CalculatorPrefs.set1rmUnit(_unit);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            // Unit toggle
                            _UnitToggle(
                              selected: _unit,
                              onTap: (u) {
                                setState(() => _unit = u);
                                CalculatorPrefs.set1rmUnit(u);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Calculator card ──────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border.all(color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section label + View Table link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1RM CALCULATOR',
                              style: AppTypography.sectionLabel
                                  .copyWith(color: AppColors.label2),
                            ),
                            GestureDetector(
                              onTap: wKg != null ? _saveAndNavigateTable : null,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(AppIcons.chart,
                                      size: 12,
                                      color: wKg != null
                                          ? AppColors.textTertiary
                                          : AppColors.disabled),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Full Table',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: wKg != null
                                          ? AppColors.textTertiary
                                          : AppColors.disabled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s16),

                        // % chips
                        Row(
                          children: _quickPcts.map((p) {
                            final active = p == activeChip;
                            final isLast = p == _quickPcts.last;
                            return Expanded(
                              child: Padding(
                                padding:
                                    EdgeInsets.only(right: isLast ? 0 : 4),
                                child: GestureDetector(
                                  onTap: () => _tapChip(p),
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.chipSelected
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: AppColors.separator,
                                          width: 0.5),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$p%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: active
                                              ? Colors.white
                                              : AppColors.label2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.s12),

                        // % input + result row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius:
                                            BorderRadius.circular(7),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _pctCtrl,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                      decimal: true),
                                              textAlign: TextAlign.right,
                                              cursorColor: AppColors.label1,
                                              cursorWidth: 1.5,
                                              cursorHeight: 14,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.label1,
                                              ),
                                              decoration:
                                                  const InputDecoration(
                                                border: InputBorder.none,
                                                enabledBorder:
                                                    InputBorder.none,
                                                focusedBorder:
                                                    InputBorder.none,
                                                filled: false,
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.only(
                                                        left: 6,
                                                        top: 6,
                                                        bottom: 6),
                                              ),
                                              onChanged: (_) =>
                                                  setState(() {}),
                                              onTap: () =>
                                                  _pctCtrl.selection =
                                                      TextSelection(
                                                baseOffset: 0,
                                                extentOffset:
                                                    _pctCtrl.text.length,
                                              ),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                left: 2, right: 7),
                                            child: Text(
                                              '%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.label2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      resultDisplay,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.label1,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Expanded(flex: 1, child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Unit toggle (KG / LBS) ────────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onTap;

  const _UnitToggle({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitChip(label: 'KG', active: selected == 'kg', onTap: () => onTap('kg')),
          _UnitChip(label: 'LBS', active: selected == 'lbs', onTap: () => onTap('lbs')),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _UnitChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.chipSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.label2,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/calculators/one_rm_calculator_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/calculators/one_rm_calculator_screen.dart
git commit -m "feat: standalone 1RM calculator screen"
```

---

## Task 8: Pace Calculator screen

**Files:**
- Create: `lib/features/calculators/pace_calculator_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/calculators/pace_calculator_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';
import 'pace_calculator_logic.dart';

// Distance presets
class _Preset {
  final String label;
  final double km;
  const _Preset(this.label, this.km);
}

const _presets = [
  _Preset('1 km', 1.0),
  _Preset('2 km', 2.0),
  _Preset('3 km', 3.0),
  _Preset('5 km', 5.0),
  _Preset('10 km', 10.0),
  _Preset('Half', PaceCalculatorLogic.halfMarathonKm),
  _Preset('Marathon', PaceCalculatorLogic.marathonKm),
  _Preset('Custom', -1.0), // -1 signals custom
];

class PaceCalculatorScreen extends StatefulWidget {
  const PaceCalculatorScreen({super.key});

  @override
  State<PaceCalculatorScreen> createState() => _PaceCalculatorScreenState();
}

class _PaceCalculatorScreenState extends State<PaceCalculatorScreen> {
  final _timeCtrl = TextEditingController();
  final _paceCtrl = TextEditingController();
  final _customDistCtrl = TextEditingController();

  String _selectedPreset = '5 km';
  double _distanceKm = 5.0;
  String _lastEdited = ''; // 'time' or 'pace'
  bool _splitsExpanded = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final preset = await CalculatorPrefs.getPacePreset();
    final distKm = await CalculatorPrefs.getPaceDistanceKm();
    final timeText = await CalculatorPrefs.getPaceTimeText();
    final paceText = await CalculatorPrefs.getPacePaceText();
    final lastEdited = await CalculatorPrefs.getPaceLastEdited();
    if (!mounted) return;
    setState(() {
      _selectedPreset = preset;
      _distanceKm = distKm;
      if (_selectedPreset == 'Custom') {
        _customDistCtrl.text = distKm.toStringAsFixed(
            distKm == distKm.roundToDouble() ? 0 : 2);
      }
      _timeCtrl.text = timeText;
      _paceCtrl.text = paceText;
      _lastEdited = lastEdited;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _paceCtrl.dispose();
    _customDistCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(String label) {
    final preset = _presets.firstWhere((p) => p.label == label);
    setState(() {
      _selectedPreset = label;
      if (preset.km > 0) _distanceKm = preset.km;
    });
    CalculatorPrefs.setPacePreset(label);
    if (preset.km > 0) {
      CalculatorPrefs.setPaceDistanceKm(preset.km);
      _recompute();
    }
  }

  void _onCustomDistChanged(String val) {
    final d = double.tryParse(val);
    if (d != null && d > 0) {
      _distanceKm = d;
      CalculatorPrefs.setPaceDistanceKm(d);
      _recompute();
    }
  }

  void _onTimeChanged(String val) {
    setState(() => _lastEdited = 'time');
    CalculatorPrefs.setPaceTimeText(val);
    CalculatorPrefs.setPaceLastEdited('time');
    _recompute();
  }

  void _onPaceChanged(String val) {
    setState(() => _lastEdited = 'pace');
    CalculatorPrefs.setPacePaceText(val);
    CalculatorPrefs.setPaceLastEdited('pace');
    _recompute();
  }

  void _recompute() {
    if (_lastEdited == 'time') {
      final secs = PaceCalculatorLogic.parseTimeOrPace(_timeCtrl.text);
      if (secs != null && _distanceKm > 0) {
        final pace = PaceCalculatorLogic.paceSecondsPerKm(
          distanceKm: _distanceKm,
          totalSeconds: secs,
        );
        if (pace != null) {
          final formatted = PaceCalculatorLogic.formatPace(pace);
          if (_paceCtrl.text != formatted) {
            _paceCtrl.text = formatted;
            CalculatorPrefs.setPacePaceText(formatted);
          }
        }
      }
    } else if (_lastEdited == 'pace') {
      final paceSec = PaceCalculatorLogic.parseTimeOrPace(_paceCtrl.text);
      if (paceSec != null && _distanceKm > 0) {
        final totalSec = PaceCalculatorLogic.totalSeconds(
          distanceKm: _distanceKm,
          paceSecondsPerKm: paceSec.toDouble(),
        );
        if (totalSec != null) {
          final formatted = PaceCalculatorLogic.formatTime(totalSec);
          if (_timeCtrl.text != formatted) {
            _timeCtrl.text = formatted;
            CalculatorPrefs.setPaceTimeText(formatted);
          }
        }
      }
    }
    setState(() {});
  }

  // Returns (paceSecPerKm, totalSec) if fully computed, else (null, null)
  (double?, int?) get _computed {
    final paceSec = PaceCalculatorLogic.parseTimeOrPace(_paceCtrl.text);
    final timeSec = PaceCalculatorLogic.parseTimeOrPace(_timeCtrl.text);
    if (paceSec != null && timeSec != null) {
      return (paceSec.toDouble(), timeSec);
    }
    return (null, null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final (paceSecPerKm, totalSec) = _computed;
    final hasSplits = paceSecPerKm != null && paceSecPerKm > 0;
    final splits = hasSplits
        ? PaceCalculatorLogic.generateSplits(_distanceKm, paceSecPerKm!)
        : <(String, int)>[];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const ScreenHeader(backLabel: 'Calculators', title: 'Pace Calculator'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s24,
                ),
                children: [
                  // ── Distance presets ────────────────────────────────
                  _SectionLabel('DISTANCE'),
                  const SizedBox(height: AppSpacing.s8),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final p = _presets[i];
                        final active = _selectedPreset == p.label;
                        return GestureDetector(
                          onTap: () => _selectPreset(p.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.chipSelected
                                  : AppColors.chip,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : AppColors.textPrimaryAlt,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedPreset == 'Custom') ...[
                    const SizedBox(height: AppSpacing.s8),
                    _InputCard(
                      label: 'CUSTOM DISTANCE (KM)',
                      child: TextField(
                        controller: _customDistCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: AppTypography.inputValue
                            .copyWith(color: AppColors.label1),
                        cursorColor: AppColors.label1,
                        decoration: InputDecoration(
                          hintText: '5.0',
                          hintStyle: AppTypography.inputValue
                              .copyWith(color: AppColors.label2),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffix: Text(
                            'km',
                            style: AppTypography.inputValue
                                .copyWith(color: AppColors.label2),
                          ),
                        ),
                        onChanged: _onCustomDistChanged,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),

                  // ── Time input ───────────────────────────────────────
                  _SectionLabel('TARGET TIME'),
                  const SizedBox(height: AppSpacing.s8),
                  _InputCard(
                    label: 'H:MM:SS or MM:SS',
                    child: TextField(
                      controller: _timeCtrl,
                      keyboardType: TextInputType.datetime,
                      style: AppTypography.inputValue
                          .copyWith(color: AppColors.label1),
                      cursorColor: AppColors.label1,
                      decoration: InputDecoration(
                        hintText: '20:00',
                        hintStyle: AppTypography.inputValue
                            .copyWith(color: AppColors.label2),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onTimeChanged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // ── Pace input ───────────────────────────────────────
                  _SectionLabel('TARGET PACE'),
                  const SizedBox(height: AppSpacing.s8),
                  _InputCard(
                    label: 'M:SS /km',
                    child: TextField(
                      controller: _paceCtrl,
                      keyboardType: TextInputType.datetime,
                      style: AppTypography.inputValue
                          .copyWith(color: AppColors.label1),
                      cursorColor: AppColors.label1,
                      decoration: InputDecoration(
                        hintText: '4:00',
                        hintStyle: AppTypography.inputValue
                            .copyWith(color: AppColors.label2),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffix: Text(
                          '/km',
                          style: AppTypography.inputValue
                              .copyWith(color: AppColors.label2),
                        ),
                      ),
                      onChanged: _onPaceChanged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  // ── Result cards ─────────────────────────────────────
                  if (paceSecPerKm != null || totalSec != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ResultCard(
                            label: 'PACE',
                            value: paceSecPerKm != null
                                ? '${PaceCalculatorLogic.formatPace(paceSecPerKm!)} /km'
                                : '—',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: _ResultCard(
                            label: 'TIME',
                            value: totalSec != null
                                ? PaceCalculatorLogic.formatTime(totalSec!)
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],

                  // ── Split table ──────────────────────────────────────
                  if (hasSplits && splits.isNotEmpty) ...[
                    _SplitTable(
                      splits: splits,
                      expanded: _splitsExpanded,
                      onToggle: () =>
                          setState(() => _splitsExpanded = !_splitsExpanded),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 0),
        child: Text(
          text,
          style: AppTypography.sectionLabel.copyWith(color: AppColors.label2),
        ),
      );
}

class _InputCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _InputCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.inputLabel.copyWith(color: AppColors.label2)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  const _ResultCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTypography.sectionLabel.copyWith(color: AppColors.label2)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.calcValue.copyWith(color: AppColors.label1),
          ),
        ],
      ),
    );
  }
}

class _SplitTable extends StatelessWidget {
  final List<(String, int)> splits;
  final bool expanded;
  final VoidCallback onToggle;

  const _SplitTable({
    required this.splits,
    required this.expanded,
    required this.onToggle,
  });

  // The 1km split is the first split where label is '1km' (or the last if < 1km)
  (String, int)? get _hundredMSplit =>
      splits.where((s) => s.$1 == '100m').firstOrNull;
  (String, int)? get _oneKmSplit =>
      splits.where((s) => s.$1 == '1km').firstOrNull;

  // Sub-1km splits (100m through 900m / total distance)
  List<(String, int)> get _subKm =>
      splits.where((s) => s.$1.endsWith('m') && !s.$1.contains('km')).toList();

  // km+ splits: 1km and above, including finish line
  List<(String, int)> get _kmPlus =>
      splits.where((s) => s.$1.contains('km')).toList();

  @override
  Widget build(BuildContext context) {
    final split100m = _hundredMSplit;
    final split1km = _oneKmSplit ?? splits.lastOrNull;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Collapsed summary rows
          if (split100m != null)
            _SplitRow(
                label: '100m Split',
                time: PaceCalculatorLogic.formatTime(split100m.$2)),
          if (split100m != null && split1km != null)
            const Divider(height: 1, thickness: 0.5, color: AppColors.separator),
          if (split1km != null)
            _SplitRow(
              label: split1km.$1 == '1km' ? '1km Split' : '${split1km.$1} Split',
              time: PaceCalculatorLogic.formatTime(split1km.$2),
            ),

          // Expanded detail
          if (expanded) ...[
            const Divider(height: 1, thickness: 0.5, color: AppColors.separator),
            ..._buildDetailRows(),
          ],

          // Toggle button
          const Divider(height: 1, thickness: 0.5, color: AppColors.separator),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    expanded ? 'Hide Splits' : 'Show Detailed Splits',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.label2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? AppIcons.caretUp : AppIcons.caretDown,
                    size: 16,
                    color: AppColors.label2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailRows() {
    final rows = <Widget>[];
    final subKm = _subKm;
    final kmPlus = _kmPlus;

    for (int i = 0; i < subKm.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 0.5, color: AppColors.separator));
      }
      final s = subKm[i];
      rows.add(_SplitRow(
          label: s.$1, time: PaceCalculatorLogic.formatTime(s.$2)));
    }

    if (subKm.isNotEmpty && kmPlus.isNotEmpty) {
      rows.add(const Divider(
          height: 1, thickness: 1.5, color: AppColors.separator));
    }

    for (int i = 0; i < kmPlus.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 0.5, color: AppColors.separator));
      }
      final s = kmPlus[i];
      rows.add(_SplitRow(
          label: s.$1, time: PaceCalculatorLogic.formatTime(s.$2)));
    }

    return rows;
  }
}

class _SplitRow extends StatelessWidget {
  final String label;
  final String time;
  const _SplitRow({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.label1)),
          Text(time,
              style: AppTypography.tableCell
                  .copyWith(color: AppColors.label1)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/calculators/pace_calculator_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/calculators/pace_calculator_screen.dart
git commit -m "feat: pace calculator screen with bidirectional calculation and split table"
```

---

## Task 9: Plate Calculator screen

**Files:**
- Create: `lib/features/calculators/plate_calculator_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/calculators/plate_calculator_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';
import 'plate_calculator_logic.dart';

class PlateCalculatorScreen extends StatefulWidget {
  const PlateCalculatorScreen({super.key});

  @override
  State<PlateCalculatorScreen> createState() => _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends State<PlateCalculatorScreen> {
  final _totalCtrl = TextEditingController();

  String _unit = 'kg'; // 'kg' or 'lb'
  double _barWeight = 20.0;
  Map<double, int> _counts = {};
  bool _loaded = false;

  List<double> get _plateSizes =>
      _unit == 'kg' ? PlateCalculatorLogic.kgPlates : PlateCalculatorLogic.lbPlates;

  List<double> get _barOptions =>
      _unit == 'kg' ? PlateCalculatorLogic.kgBars : PlateCalculatorLogic.lbBars;

  String get _unitLabel => _unit == 'kg' ? 'kg' : 'lb';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final unit = await CalculatorPrefs.getPlateUnit();
    final barWeight = await CalculatorPrefs.getPlateBarWeight();
    final totalWeight = await CalculatorPrefs.getPlateTotalWeight();
    final savedCounts = await CalculatorPrefs.getPlateCounts(unit);

    if (!mounted) return;
    setState(() {
      _unit = unit;
      _barWeight = barWeight;
      // Restore plate counts for current unit, defaulting to 0
      final sizes = unit == 'kg'
          ? PlateCalculatorLogic.kgPlates
          : PlateCalculatorLogic.lbPlates;
      _counts = {
        for (final s in sizes) s: savedCounts[s] ?? 0,
      };
      _totalCtrl.text = _fmtWeight(totalWeight);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    super.dispose();
  }

  String _fmtWeight(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? v.toInt().toString() : s;
  }

  // Called when user edits Total Weight field
  void _onTotalChanged(String raw) {
    final target = double.tryParse(raw);
    if (target == null || target <= 0) return;
    final solved = PlateCalculatorLogic.solvePlates(
      totalWeightTarget: target,
      barWeight: _barWeight,
      plateSizes: _plateSizes,
    );
    setState(() {
      _counts = {for (final s in _plateSizes) s: solved[s] ?? 0};
    });
    CalculatorPrefs.setPlateTotalWeight(target);
    CalculatorPrefs.setPlateCounts(_unit, _counts);
  }

  // Called when user taps +/- on a plate row
  void _adjustCount(double plate, int delta) {
    final current = _counts[plate] ?? 0;
    final next = (current + delta).clamp(0, 40);
    // Must stay even
    final evenNext = next % 2 == 0 ? next : next - 1;
    setState(() {
      _counts[plate] = evenNext;
    });
    final total = PlateCalculatorLogic.computeTotal(
      barWeight: _barWeight,
      plateCounts: _counts,
    );
    _totalCtrl.text = _fmtWeight(total);
    CalculatorPrefs.setPlateTotalWeight(total);
    CalculatorPrefs.setPlateCounts(_unit, _counts);
  }

  void _selectBar(double weight) {
    setState(() => _barWeight = weight);
    CalculatorPrefs.setPlateBarWeight(weight);
    // Recompute total from existing plate counts
    final total = PlateCalculatorLogic.computeTotal(
      barWeight: weight,
      plateCounts: _counts,
    );
    _totalCtrl.text = _fmtWeight(total);
    CalculatorPrefs.setPlateTotalWeight(total);
  }

  void _switchUnit(String newUnit) {
    if (newUnit == _unit) return;
    CalculatorPrefs.setPlateUnit(newUnit);
    // Reset to defaults for new unit
    final newBar = newUnit == 'kg' ? 20.0 : 45.0;
    final newSizes = newUnit == 'kg'
        ? PlateCalculatorLogic.kgPlates
        : PlateCalculatorLogic.lbPlates;
    setState(() {
      _unit = newUnit;
      _barWeight = newBar;
      _counts = {for (final s in newSizes) s: 0};
      _totalCtrl.text = _fmtWeight(newBar);
    });
    CalculatorPrefs.setPlateBarWeight(newBar);
    CalculatorPrefs.setPlateTotalWeight(newBar);
    CalculatorPrefs.setPlateCounts(newUnit, _counts);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const ScreenHeader(
                backLabel: 'Calculators', title: 'Plate Calculator'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s24,
                ),
                children: [
                  // ── Unit toggle ──────────────────────────────────────
                  Center(
                    child: _KgLbToggle(
                      selected: _unit,
                      onTap: _switchUnit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Total Weight input ───────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border.all(color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL WEIGHT',
                          style: AppTypography.sectionLabel
                              .copyWith(color: AppColors.label2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _totalCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: AppTypography.inputValue
                                    .copyWith(color: AppColors.label1),
                                cursorColor: AppColors.label1,
                                decoration: InputDecoration(
                                  hintText: '100',
                                  hintStyle: AppTypography.inputValue
                                      .copyWith(color: AppColors.label2),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: _onTotalChanged,
                              ),
                            ),
                            Text(
                              _unitLabel,
                              style: AppTypography.inputValue
                                  .copyWith(color: AppColors.label2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Bar selector ─────────────────────────────────────
                  Text(
                    'BAR',
                    style: AppTypography.sectionLabel
                        .copyWith(color: AppColors.label2),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: _barOptions.map((w) {
                      final active = (w - _barWeight).abs() < 0.01;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _selectBar(w),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.chipSelected
                                  : AppColors.chip,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_fmtWeight(w)}$_unitLabel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AppColors.textPrimaryAlt,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Plate rows ───────────────────────────────────────
                  Text(
                    'PLATES',
                    style: AppTypography.sectionLabel
                        .copyWith(color: AppColors.label2),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: _plateSizes.asMap().entries.map((entry) {
                        final i = entry.key;
                        final plate = entry.value;
                        final count = _counts[plate] ?? 0;
                        return Column(
                          children: [
                            if (i > 0)
                              const Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: AppColors.separator),
                            _PlateRow(
                              plate: plate,
                              unitLabel: _unitLabel,
                              count: count,
                              onMinus: count > 0
                                  ? () => _adjustCount(plate, -2)
                                  : null,
                              onPlus: () => _adjustCount(plate, 2),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KG / LB toggle ────────────────────────────────────────────────────────────

class _KgLbToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onTap;

  const _KgLbToggle({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'KG', active: selected == 'kg', onTap: () => onTap('kg')),
          _Tab(label: 'LB', active: selected == 'lb', onTap: () => onTap('lb')),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.label1 : AppColors.label2,
          ),
        ),
      ),
    );
  }
}

// ── Plate row ─────────────────────────────────────────────────────────────────

class _PlateRow extends StatelessWidget {
  final double plate;
  final String unitLabel;
  final int count;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const _PlateRow({
    required this.plate,
    required this.unitLabel,
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    if (s.endsWith('00')) return v.toInt().toString();
    if (s.endsWith('0')) return v.toStringAsFixed(1);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '${_fmt(plate)}$unitLabel',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.label1,
              ),
            ),
          ),
          const Spacer(),
          // Minus button
          _StepButton(
            icon: '−',
            enabled: onMinus != null,
            onTap: onMinus,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.label1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Plus button
          _StepButton(icon: '+', enabled: true, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.chip,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.separator,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: enabled ? AppColors.label1 : AppColors.disabled,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/calculators/plate_calculator_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/calculators/plate_calculator_screen.dart
git commit -m "feat: plate calculator screen with bidirectional weight/plate sync"
```

---

## Task 10: Home header swap + Router wiring

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Swap Profile button to Calculator in home_screen.dart**

In `lib/features/home/home_screen.dart`, find the Profile icon button block (lines ~164–170):

```dart
GestureDetector(
  onTap: () => context.push('/profile'),
  child: _IconButton(icon: AppIcons.person),
),
```

Replace with:

```dart
GestureDetector(
  onTap: () => context.push('/calculators'),
  child: _IconButton(icon: AppIcons.calculator),
),
```

- [ ] **Step 2: Add routes and imports in app.dart**

In `lib/app.dart`, add imports after line 16 (`import 'features/settings/settings_screen.dart';`):

```dart
import 'features/calculators/calculator_hub_screen.dart';
import 'features/calculators/one_rm_calculator_screen.dart';
import 'features/calculators/pace_calculator_screen.dart';
import 'features/calculators/plate_calculator_screen.dart';
```

In `_router`'s `routes` list, add after the `/settings` route:

```dart
GoRoute(
  path: '/calculators',
  builder: (context, state) => const CalculatorHubScreen(),
),
GoRoute(
  path: '/calculators/1rm',
  builder: (context, state) => const OneRmCalculatorScreen(),
),
GoRoute(
  path: '/calculators/1rm-table',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return OneRMTableScreen(
      directWeightKg: (extra?['weight'] as num?)?.toDouble(),
      directWeightUnit: extra?['unit'] as String?,
    );
  },
),
GoRoute(
  path: '/calculators/pace',
  builder: (context, state) => const PaceCalculatorScreen(),
),
GoRoute(
  path: '/calculators/plate',
  builder: (context, state) => const PlateCalculatorScreen(),
),
```

- [ ] **Step 3: Analyze both files**

```bash
flutter analyze lib/features/home/home_screen.dart lib/app.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/home_screen.dart lib/app.dart
git commit -m "feat: wire calculator hub into home header and router"
```

---

## Task 11: Uncategorized row polish

**Files:**
- Modify: `lib/features/categories/category_management_screen.dart`

- [ ] **Step 1: Fix drag handle in _CategoryTile**

In `_CategoryTile.build()`, find the `leading` row. The current code wraps ALL tiles' drag handles in `ReorderableDragStartListener`, including Uncategorized. Replace the leading Row with a conditional:

Current code to replace (in `_CategoryTile.build()`):
```dart
leading: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    ReorderableDragStartListener(
      index: index,
      child: Icon(AppIcons.dragHandle, color: const Color(0xFFD1D5DA), size: 18),
    ),
    const SizedBox(width: 10),
    _colorDot(),
  ],
),
```

Replace with:
```dart
leading: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    isUncategorized
        ? Icon(AppIcons.dragHandle, color: const Color(0xFFD1D5DA), size: 18)
        : ReorderableDragStartListener(
            index: index,
            child: Icon(AppIcons.dragHandle, color: const Color(0xFFD1D5DA), size: 18),
          ),
    const SizedBox(width: 10),
    _colorDot(),
  ],
),
```

- [ ] **Step 2: Guard _reorder against Uncategorized**

Find `_reorder` in `_CategoryManagementScreenState`. Add a guard at the top of the method body:

```dart
Future<void> _reorder(List<Category> cats, int oldIdx, int newIdx) async {
  if (cats[oldIdx].id == Category.uncategorizedId) return;  // ← add this
  final reordered = List<Category>.from(cats);
  ...
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/categories/category_management_screen.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/categories/category_management_screen.dart
git commit -m "fix: Uncategorized row shows visual drag handle without drag interaction"
```

---

## Task 12: Full verify — analyze + test

- [ ] **Step 1: Run flutter analyze across the full project**

```bash
cd /Users/ida-eun/projects/peaklog && flutter analyze
```

Expected: no issues. Fix any reported issues before proceeding.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: all tests pass, including:
- `test/features/calculators/pace_calculator_logic_test.dart`
- `test/features/calculators/plate_calculator_logic_test.dart`
- All pre-existing tests

- [ ] **Step 3: Final commit**

If any fixes were needed during analyze/test, commit them now:

```bash
git add -p  # review and stage any fixes
git commit -m "fix: analyzer and test corrections"
```

---

## Spec Coverage Checklist

| Spec section | Task(s) |
|---|---|
| Home header: Profile → Calculator | Task 10 |
| Calculator Hub (3 cards, card navigation) | Task 6, Task 10 |
| 1RM Calculator (reuse logic, View Full Table) | Task 7, Task 5 |
| OneRMTableScreen: direct weight mode | Task 5 |
| Pace Calculator (bidirectional, presets, custom) | Task 8, Task 2 |
| Pace result cards (PACE, TIME) | Task 8 |
| Split table (collapsed/expanded, 100m+km rules) | Task 8, Task 2 |
| Half Marathon / Marathon splits | Task 2, Task 8 |
| Plate Calculator (KG/LB toggle, bar chips) | Task 9, Task 3 |
| Plate bidirectional (total↔plates) | Task 9, Task 3 |
| Plate even counts (0, 2, 4…) | Task 9, Task 3 |
| Persistence (SharedPreferences) | Task 4 + each screen |
| Calculator icon (not gear/toolbox/wrench) | Task 1 |
| Uncategorized: visual handle, no drag | Task 11 |
| flutter analyze | Task 12 |
| flutter test | Task 12 |
