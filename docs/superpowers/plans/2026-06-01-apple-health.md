# Apple Health / Health Connect Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Import running workouts from Apple Health (iOS) / Health Connect (Android), auto-detect segment PBs (1km/5km/10km/Half/Full), deduplicate imports, and show results in a Health Sync screen.

**Architecture:** `HealthSyncService` fetches workouts from the `health` package, matches total distance to target segments (±50m), deduplicates via a `health_imports` table (hash of distance+duration+startTime), creates Records for new data, and detects PBs. DB bumps to v4 to add the `health_imports` table. The sync is always user-triggered (never on app start) per the spec.

**Tech Stack:** Flutter, `health` package (HealthKit/Health Connect), Riverpod, existing DB Foundation models

**⚠️ Manual Xcode step required (Task 7):** HealthKit capability must be enabled in Xcode → Signing & Capabilities — cannot be done via file edits alone.

---

## File Map

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` |
| Create | `lib/core/models/health_import.dart` |
| Modify | `lib/core/database/database_helper.dart` |
| Create | `lib/core/services/health_sync_service.dart` |
| Create | `lib/features/health/health_sync_screen.dart` |
| Modify | `lib/features/settings/settings_screen.dart` |
| Modify | `ios/Runner/Info.plist` |
| Create | `ios/Runner/Runner.entitlements` |

---

### Task 1: Add health package

**Files:** `pubspec.yaml`

- [ ] Add under `dependencies:`:

```yaml
  health: ^11.0.0
```

- [ ] Run `flutter pub get`

- [ ] Commit:
```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add health package for Apple Health / Health Connect integration"
```

---

### Task 2: Create HealthImport model

**Files:** Create `lib/core/models/health_import.dart`

- [ ] Create file:

```dart
class HealthImport {
  final String id;      // deduplication hash: "${distM}_${durationSec}_${startMs}"
  final String? recordId;
  final int importedAt; // ms since epoch

  const HealthImport({
    required this.id,
    this.recordId,
    required this.importedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'record_id': recordId,
    'imported_at': importedAt,
  };

  factory HealthImport.fromMap(Map<String, dynamic> map) => HealthImport(
    id: map['id'] as String,
    recordId: map['record_id'] as String?,
    importedAt: (map['imported_at'] as num).toInt(),
  );
}
```

---

### Task 3: Bump DB to v4, add health_imports table + query methods

**Files:** `lib/core/database/database_helper.dart`

- [ ] Change `version: 3` → `version: 4`:

```dart
      version: 4,
```

- [ ] In `onUpgrade`, change `_onCreate(db, newVersion)` to also include v3→v4:
```dart
      onUpgrade: (db, oldVersion, newVersion) async {
        // dev: drop all and recreate
        await db.execute('DROP TABLE IF EXISTS health_imports');
        await db.execute('DROP TABLE IF EXISTS sync_tasks');
        await db.execute('DROP TABLE IF EXISTS personal_bests');
        await db.execute('DROP TABLE IF EXISTS records');
        await db.execute('DROP TABLE IF EXISTS exercises');
        await _onCreate(db, newVersion);
      },
```

- [ ] In `_onCreate`, add the `health_imports` table AFTER `sync_tasks`:

```dart
    await db.execute('''
      CREATE TABLE health_imports (
        id TEXT PRIMARY KEY,
        record_id TEXT,
        imported_at INTEGER NOT NULL
      )
    ''');
```

- [ ] Add 3 methods at the bottom of the DatabaseHelper class, before `close()`:

```dart
  // ── HEALTH IMPORTS ─────────────────────────────────────────

  Future<bool> hasHealthImport(String hash) async {
    final db = await database;
    final result = await db.query('health_imports',
        where: 'id = ?', whereArgs: [hash], limit: 1);
    return result.isNotEmpty;
  }

  Future<void> insertHealthImport(HealthImport imp) async {
    final db = await database;
    await db.insert('health_imports', imp.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int?> getBestDurationForExercise(String exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'records',
      columns: ['duration_seconds'],
      where: 'exercise_id = ? AND is_deleted = 0 AND duration_seconds IS NOT NULL',
      whereArgs: [exerciseId],
      orderBy: 'duration_seconds ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['duration_seconds'] as num).toInt();
  }
```

- [ ] Add `import '../models/health_import.dart';` and `import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;` at the top of the file.

  Actually `ConflictAlgorithm` is already exported from `package:sqflite/sqflite.dart` — ensure it's imported:
```dart
import 'package:sqflite/sqflite.dart';
```
  (The existing import already covers this.)

---

### Task 4: Create HealthSyncService

**Files:** Create `lib/core/services/health_sync_service.dart`

- [ ] Create file:

```dart
import 'package:health/health.dart';
import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../models/health_import.dart';
import '../models/record.dart';
import '../utils/unit_converter.dart';

class SyncResult {
  final int imported;
  final int skipped;
  final List<String> newPbs;

  const SyncResult({
    required this.imported,
    required this.skipped,
    required this.newPbs,
  });
}

class _Segment {
  final String displayName;
  final double distanceM;
  const _Segment(this.displayName, this.distanceM);
}

class HealthSyncService {
  static const _toleranceM = 50.0;

  static const _segments = [
    _Segment('1km Run', 1000),
    _Segment('5km Run', 5000),
    _Segment('10km Run', 10000),
    _Segment('Half Marathon', 21097),
    _Segment('Full Marathon', 42195),
  ];

  final _health = Health();

  Future<bool> requestPermission() async {
    final types = [HealthDataType.WORKOUT];
    return _health.requestAuthorization(types);
  }

  Future<bool> get isAvailable async {
    return Health.isAvailable;
  }

  Future<SyncResult> syncRunningWorkouts() async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: [HealthDataType.WORKOUT],
    );

    int imported = 0;
    int skipped = 0;
    final newPbs = <String>[];

    for (final dp in dataPoints) {
      if (dp.value is! WorkoutHealthValue) continue;
      final workout = dp.value as WorkoutHealthValue;

      if (workout.workoutActivityType !=
          HealthWorkoutActivityType.RUNNING) continue;

      final distM = workout.totalDistance;
      if (distM == null || distM <= 0) continue;

      final durationSec =
          dp.dateTo.difference(dp.dateFrom).inSeconds;
      if (durationSec <= 0) continue;

      // Match to a target segment
      _Segment? matched;
      for (final seg in _segments) {
        if ((distM - seg.distanceM).abs() <= _toleranceM) {
          matched = seg;
          break;
        }
      }
      if (matched == null) continue;

      // Deduplication hash
      final hash =
          '${distM.round()}_${durationSec}_${dp.dateFrom.millisecondsSinceEpoch ~/ 1000}';
      if (await db.hasHealthImport(hash)) {
        skipped++;
        continue;
      }

      // Find or create running exercise
      final exercise =
          await _findOrCreateRunningExercise(db, matched.displayName);

      // Check previous best before insert
      final prevBestSec =
          await db.getBestDurationForExercise(exercise.id);

      // Create record
      final record = Record.create(
        exerciseId: exercise.id,
        performedAt: dp.dateFrom.millisecondsSinceEpoch,
        distance: distM / 1000,
        durationSeconds: durationSec,
      );
      await db.insertRecord(record);

      // Log import (dedup)
      await db.insertHealthImport(HealthImport(
        id: hash,
        recordId: record.id,
        importedAt: now.millisecondsSinceEpoch,
      ));

      // PB detection
      if (prevBestSec == null || durationSec < prevBestSec) {
        newPbs.add(
            '${matched.displayName}  ${UnitConverter.secondsToDisplay(durationSec)}');
      }

      imported++;
    }

    return SyncResult(
        imported: imported, skipped: skipped, newPbs: newPbs);
  }

  Future<Exercise> _findOrCreateRunningExercise(
      DatabaseHelper db, String displayName) async {
    final exercises = await db.getExercises();
    final normalized = normalizeExerciseName(displayName);
    final existing = exercises
        .where((e) => e.normalizedName == normalized)
        .firstOrNull;
    if (existing != null) return existing;

    final exercise = Exercise.create(
      displayName: displayName,
      category: ExerciseCategory.running,
      orderIndex: exercises.length,
    );
    await db.insertExercise(exercise);
    return exercise;
  }
}

final healthSyncService = HealthSyncService();
```

---

### Task 5: Create HealthSyncScreen

**Files:** Create `lib/features/health/health_sync_screen.dart`

- [ ] Create directory: `lib/features/health/`

- [ ] Create file:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/services/health_sync_service.dart';
import '../../core/theme/app_theme.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  bool _syncing = false;
  SyncResult? _lastResult;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강 앱 연동')),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(),
                  const SizedBox(height: 20),
                  if (_errorMsg != null) ...[
                    _ErrorCard(message: _errorMsg!),
                    const SizedBox(height: 16),
                  ],
                  if (_lastResult != null) ...[
                    _ResultCard(result: _lastResult!),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _syncing ? null : _startSync,
                      child: _syncing
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text('가져오는 중...'),
                              ],
                            )
                          : const Text('러닝 데이터 가져오기'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '최근 90일 이내의 러닝 기록을 자동으로 가져옵니다.\n'
                    '1km / 5km / 10km / 하프 / 풀 마라톤 기록이 자동으로 생성됩니다.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSync() async {
    setState(() {
      _syncing = true;
      _errorMsg = null;
      _lastResult = null;
    });
    try {
      // Permission request happens here (on feature entry, never on app start)
      final granted = await healthSyncService.requestPermission();
      if (!granted) {
        setState(() => _errorMsg = '건강 앱 접근 권한이 필요합니다.\n설정 앱에서 PeakLog의 건강 데이터 접근을 허용해주세요.');
        return;
      }
      final result = await healthSyncService.syncRunningWorkouts();
      setState(() => _lastResult = result);
    } catch (e) {
      setState(() => _errorMsg = '오류: $e');
    } finally {
      setState(() => _syncing = false);
    }
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.heart_fill,
                color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apple Health 연동',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('러닝 기록을 자동으로 가져옵니다',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SyncResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF34C759), size: 18),
              const SizedBox(width: 8),
              Text('가져오기 완료',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _StatRow(label: '새로 가져온 기록', value: '${result.imported}개'),
          if (result.skipped > 0)
            _StatRow(label: '중복 제외', value: '${result.skipped}개'),
          if (result.newPbs.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('🎉 새로운 PR',
                style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...result.newPbs.map((pb) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $pb',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                )),
          ],
          if (result.imported == 0 && result.newPbs.isEmpty)
            const Text('새로 가져올 기록이 없습니다.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle,
              color: Color(0xFFFF3B30), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFFF3B30), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
```

---

### Task 6: Add health sync entry to SettingsScreen

**Files:** `lib/features/settings/settings_screen.dart`

- [ ] Add the following import at the top of the file:

```dart
import '../health/health_sync_screen.dart';
```

- [ ] In the `build` method's `ListView` children, add a health section before `'앱 정보'`. Find this block and insert before it:

```dart
          const SizedBox(height: 32),
          const _SectionHeader('앱 정보'),
```

Replace with:

```dart
          const SizedBox(height: 32),
          const _SectionHeader('건강 앱'),
          _NavRow(
            title: 'Apple Health 연동',
            subtitle: '러닝 기록 자동 가져오기',
            icon: CupertinoIcons.heart_fill,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const HealthSyncScreen()),
            ),
          ),
          const SizedBox(height: 32),
          const _SectionHeader('앱 정보'),
```

- [ ] Add the `_NavRow` widget at the bottom of `settings_screen.dart` (before the closing of the file):

```dart
class _NavRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 16)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right,
                  color: AppTheme.separator, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Task 7: iOS permissions (manual Xcode step required)

**Files:** `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`

- [ ] Add to `ios/Runner/Info.plist` (inside `<dict>`, after the existing photo library keys):

```xml
	<key>NSHealthShareUsageDescription</key>
	<string>러닝 데이터를 자동으로 기록하기 위해 건강 앱 접근 권한이 필요합니다.</string>
	<key>NSHealthUpdateUsageDescription</key>
	<string>운동 기록을 건강 앱에 저장합니다.</string>
```

- [ ] Create `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.healthkit</key>
	<true/>
	<key>com.apple.developer.healthkit.access</key>
	<array/>
</dict>
</plist>
```

- [ ] **⚠️ MANUAL XCODE STEP** (cannot be scripted): Open `ios/Runner.xcworkspace` in Xcode → select Runner target → Signing & Capabilities tab → click `+` → add **HealthKit**. This links the entitlements file and updates `project.pbxproj`. Without this step, HealthKit APIs will crash at runtime.

---

### Task 8: Verify and commit

- [ ] Run `flutter analyze` — expect no errors.

- [ ] Fix any type errors.

- [ ] Commit:

```bash
git add -A
git commit -m "feat: Apple Health integration — running data import, segment PB detection (1km/5km/10km/Half/Full)"
```
