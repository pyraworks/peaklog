# DB Foundation Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate PeakLog from int PKs + single `value` field to UUID PKs + separate weight/reps/duration/distance fields, add PersonalBest & SyncTask tables, enforce soft delete throughout.

**Architecture:** Drop & recreate SQLite DB at version 3. New models (Exercise, Record, PersonalBest, SyncTask) use String UUID PKs. DatabaseHelper computes PersonalBest automatically on record insert/delete. All UI files updated to compile and run with new models.

**Tech Stack:** Flutter, sqflite, Riverpod 2.x, uuid package

---

## File Map

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` |
| Rewrite | `lib/core/models/exercise.dart` |
| Rewrite | `lib/core/models/record.dart` |
| Create  | `lib/core/models/personal_best.dart` |
| Create  | `lib/core/models/sync_task.dart` |
| Rewrite | `lib/core/database/database_helper.dart` |
| Rewrite | `lib/providers/exercises_provider.dart` |
| Rewrite | `lib/providers/records_provider.dart` |
| Create  | `lib/providers/personal_best_provider.dart` |
| Update  | `lib/features/home/add_exercise_sheet.dart` |
| Update  | `lib/features/home/exercise_card.dart` |
| Update  | `lib/features/home/one_rm_panel.dart` |
| Update  | `lib/features/exercise_detail/exercise_detail_screen.dart` |
| Update  | `lib/features/record_input/record_input_screen.dart` |
| Update  | `lib/features/record_input/pr_celebration_dialog.dart` |
| Update  | `lib/features/history/history_screen.dart` |
| Update  | `lib/features/export/export_screen.dart` |
| Update  | `lib/features/export/clean_frame.dart` |
| Update  | `lib/features/export/rough_frame.dart` |

---

### Task 1: Add uuid dependency

**Files:** `pubspec.yaml`

- [ ] Add `uuid: ^4.5.1` under `dependencies:` after `flutter_slidable`
- [ ] Run `flutter pub get`

---

### Task 2: Rewrite Exercise model

**Files:** `lib/core/models/exercise.dart`

- [ ] Replace entire file with:

```dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ExerciseCategory { strength, running, workout, custom }

extension ExerciseCategoryX on ExerciseCategory {
  String get label {
    switch (this) {
      case ExerciseCategory.strength: return '무게';
      case ExerciseCategory.running:  return '러닝';
      case ExerciseCategory.workout:  return '와드';
      case ExerciseCategory.custom:   return '커스텀';
    }
  }

  String get description {
    switch (this) {
      case ExerciseCategory.strength: return '스쿼트, 데드리프트 등';
      case ExerciseCategory.running:  return '5km, 10km 달리기 등';
      case ExerciseCategory.workout:  return 'Fran, Murph 등';
      case ExerciseCategory.custom:   return '기타 운동';
    }
  }
}

enum Visibility { private, public }

enum SyncStatus { pending, synced, failed }

class Exercise {
  final String id;
  final String ownerId;
  final String displayName;
  final String normalizedName;
  final ExerciseCategory category;
  final Visibility visibility;
  final bool isArchived;
  final int orderIndex;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const Exercise({
    required this.id,
    this.ownerId = 'local',
    required this.displayName,
    required this.normalizedName,
    required this.category,
    this.visibility = Visibility.private,
    this.isArchived = false,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  factory Exercise.create({
    required String displayName,
    required ExerciseCategory category,
    required int orderIndex,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Exercise(
      id: _uuid.v4(),
      displayName: displayName,
      normalizedName: normalizeExerciseName(displayName),
      category: category,
      orderIndex: orderIndex,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'display_name': displayName,
    'normalized_name': normalizedName,
    'category': category.name,
    'visibility': visibility.name,
    'is_archived': isArchived ? 1 : 0,
    'order_index': orderIndex,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String,
    displayName: map['display_name'] as String,
    normalizedName: map['normalized_name'] as String,
    category: ExerciseCategory.values.byName(map['category'] as String),
    visibility: Visibility.values.byName(map['visibility'] as String),
    isArchived: (map['is_archived'] as num).toInt() == 1,
    orderIndex: (map['order_index'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );

  Exercise copyWith({
    String? id, String? ownerId, String? displayName, String? normalizedName,
    ExerciseCategory? category, Visibility? visibility, bool? isArchived,
    int? orderIndex, int? createdAt, int? updatedAt, SyncStatus? syncStatus,
  }) => Exercise(
    id: id ?? this.id, ownerId: ownerId ?? this.ownerId,
    displayName: displayName ?? this.displayName,
    normalizedName: normalizedName ?? this.normalizedName,
    category: category ?? this.category, visibility: visibility ?? this.visibility,
    isArchived: isArchived ?? this.isArchived, orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

String normalizeExerciseName(String input) => input
    .trim().toLowerCase()
    .replaceAll(RegExp(r'\s+'), '_')
    .replaceAll(RegExp(r'[^a-z0-9_]'), '');
```

---

### Task 3: Rewrite Record model

**Files:** `lib/core/models/record.dart`

- [ ] Replace entire file with:

```dart
import 'package:uuid/uuid.dart';
import 'exercise.dart';

const _uuid = Uuid();

class Record {
  final String id;
  final String ownerId;
  final String exerciseId;
  final int performedAt;       // ms since epoch
  final double? weight;        // kg
  final int? reps;
  final int? durationSeconds;
  final double? distance;      // km
  final String? note;
  final String? mediaUrl;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const Record({
    required this.id,
    this.ownerId = 'local',
    required this.exerciseId,
    required this.performedAt,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distance,
    this.note,
    this.mediaUrl,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  factory Record.create({
    required String exerciseId,
    required int performedAt,
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distance,
    String? note,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Record(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      performedAt: performedAt,
      weight: weight,
      reps: reps,
      durationSeconds: durationSeconds,
      distance: distance,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'exercise_id': exerciseId,
    'performed_at': performedAt,
    'weight': weight,
    'reps': reps,
    'duration_seconds': durationSeconds,
    'distance': distance,
    'note': note,
    'media_url': mediaUrl,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory Record.fromMap(Map<String, dynamic> map) => Record(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String,
    exerciseId: map['exercise_id'] as String,
    performedAt: (map['performed_at'] as num).toInt(),
    weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
    reps: map['reps'] != null ? (map['reps'] as num).toInt() : null,
    durationSeconds: map['duration_seconds'] != null
        ? (map['duration_seconds'] as num).toInt() : null,
    distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
    note: map['note'] as String?,
    mediaUrl: map['media_url'] as String?,
    isDeleted: (map['is_deleted'] as num).toInt() == 1,
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );

  Record copyWith({
    String? id, String? ownerId, String? exerciseId, int? performedAt,
    double? weight, int? reps, int? durationSeconds, double? distance,
    String? note, String? mediaUrl, bool? isDeleted,
    int? createdAt, int? updatedAt, SyncStatus? syncStatus,
  }) => Record(
    id: id ?? this.id, ownerId: ownerId ?? this.ownerId,
    exerciseId: exerciseId ?? this.exerciseId,
    performedAt: performedAt ?? this.performedAt,
    weight: weight ?? this.weight, reps: reps ?? this.reps,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    distance: distance ?? this.distance, note: note ?? this.note,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
```

---

### Task 4: Create PersonalBest + SyncTask models

**Files:** `lib/core/models/personal_best.dart`, `lib/core/models/sync_task.dart`

- [ ] Create `personal_best.dart`:

```dart
import 'package:uuid/uuid.dart';
import 'exercise.dart';

const _uuid = Uuid();

enum PersonalBestType { maxWeight, bestTime, longestDistance, estimated1RM }

class PersonalBest {
  final String id;
  final String ownerId;
  final String exerciseId;
  final String sourceRecordId;
  final PersonalBestType type;
  final double value;
  final int achievedAt;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const PersonalBest({
    required this.id,
    this.ownerId = 'local',
    required this.exerciseId,
    required this.sourceRecordId,
    required this.type,
    required this.value,
    required this.achievedAt,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'owner_id': ownerId, 'exercise_id': exerciseId,
    'source_record_id': sourceRecordId, 'pb_type': type.name,
    'value': value, 'achieved_at': achievedAt,
    'created_at': createdAt, 'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory PersonalBest.fromMap(Map<String, dynamic> map) => PersonalBest(
    id: map['id'] as String, ownerId: map['owner_id'] as String,
    exerciseId: map['exercise_id'] as String,
    sourceRecordId: map['source_record_id'] as String,
    type: PersonalBestType.values.byName(map['pb_type'] as String),
    value: (map['value'] as num).toDouble(),
    achievedAt: (map['achieved_at'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );
}
```

- [ ] Create `sync_task.dart`:

```dart
import 'package:uuid/uuid.dart';
import 'exercise.dart';

const _uuid = Uuid();

class SyncTask {
  final String id;
  final String entityType;
  final String entityId;
  final String operation; // create / update / delete
  final int retryCount;
  final int createdAt;
  final SyncStatus syncStatus;

  const SyncTask({
    required this.id, required this.entityType, required this.entityId,
    required this.operation, this.retryCount = 0,
    required this.createdAt, this.syncStatus = SyncStatus.pending,
  });

  factory SyncTask.create({
    required String entityType, required String entityId, required String operation,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return SyncTask(
      id: _uuid.v4(), entityType: entityType, entityId: entityId,
      operation: operation, createdAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'entity_type': entityType, 'entity_id': entityId,
    'operation': operation, 'retry_count': retryCount,
    'created_at': createdAt, 'sync_status': syncStatus.name,
  };

  factory SyncTask.fromMap(Map<String, dynamic> map) => SyncTask(
    id: map['id'] as String, entityType: map['entity_type'] as String,
    entityId: map['entity_id'] as String, operation: map['operation'] as String,
    retryCount: (map['retry_count'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );
}
```

---

### Task 5: Rewrite DatabaseHelper

**Files:** `lib/core/database/database_helper.dart`

- [ ] Replace entire file with the v3 schema, DROP/recreate on upgrade, indexes, and PersonalBest auto-update logic. Full content:

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/record.dart';
import '../models/personal_best.dart';

const _uuid = Uuid();

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'peaklog.db'),
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS sync_tasks');
        await db.execute('DROP TABLE IF EXISTS personal_bests');
        await db.execute('DROP TABLE IF EXISTS records');
        await db.execute('DROP TABLE IF EXISTS exercises');
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL DEFAULT 'local',
        display_name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        category TEXT NOT NULL,
        visibility TEXT NOT NULL DEFAULT 'private',
        is_archived INTEGER NOT NULL DEFAULT 0,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL DEFAULT 'local',
        exercise_id TEXT NOT NULL,
        performed_at INTEGER NOT NULL,
        weight REAL,
        reps INTEGER,
        duration_seconds INTEGER,
        distance REAL,
        note TEXT,
        media_url TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    await db.execute('''
      CREATE TABLE personal_bests (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL DEFAULT 'local',
        exercise_id TEXT NOT NULL,
        source_record_id TEXT NOT NULL,
        pb_type TEXT NOT NULL,
        value REAL NOT NULL,
        achieved_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_tasks (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    await db.execute('CREATE INDEX idx_records_exercise_id ON records(exercise_id)');
    await db.execute('CREATE INDEX idx_records_owner_id ON records(owner_id)');
    await db.execute('CREATE INDEX idx_records_performed_at ON records(performed_at)');
    await db.execute('CREATE INDEX idx_records_updated_at ON records(updated_at)');
    await db.execute('CREATE INDEX idx_records_is_deleted ON records(is_deleted)');
    await db.execute('CREATE INDEX idx_pbs_exercise_id ON personal_bests(exercise_id)');
    await db.execute('CREATE INDEX idx_exercises_owner_id ON exercises(owner_id)');
  }

  // ── EXERCISES ──────────────────────────────────────────────────

  Future<void> insertExercise(Exercise exercise) async {
    final db = await database;
    await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getExercises() async {
    final db = await database;
    final maps = await db.query(
      'exercises',
      where: 'is_archived = 0',
      orderBy: 'order_index ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<void> updateExercise(Exercise exercise) async {
    final db = await database;
    await db.update('exercises', exercise.toMap(),
        where: 'id = ?', whereArgs: [exercise.id]);
  }

  Future<void> archiveExercise(String id) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('exercises', {'is_archived': 1, 'updated_at': now},
          where: 'id = ?', whereArgs: [id]);
      await txn.update('records', {'is_deleted': 1, 'updated_at': now},
          where: 'exercise_id = ? AND is_deleted = 0', whereArgs: [id]);
      await txn.delete('personal_bests', where: 'exercise_id = ?', whereArgs: [id]);
    });
  }

  // ── RECORDS ────────────────────────────────────────────────────

  Future<void> insertRecord(Record record) async {
    final db = await database;
    await db.insert('records', record.toMap());
    await _updatePersonalBest(db, record.exerciseId);
  }

  Future<List<Record>> getRecordsForExercise(String exerciseId) async {
    final db = await database;
    final maps = await db.query(
      'records',
      where: 'exercise_id = ? AND is_deleted = 0',
      whereArgs: [exerciseId],
      orderBy: 'performed_at DESC',
    );
    return maps.map(Record.fromMap).toList();
  }

  Future<void> softDeleteRecord(String recordId, String exerciseId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'records',
      {'is_deleted': 1, 'updated_at': now, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [recordId],
    );
    await _updatePersonalBest(db, exerciseId);
  }

  // ── PERSONAL BESTS ─────────────────────────────────────────────

  Future<List<PersonalBest>> getPersonalBestsForExercise(String exerciseId) async {
    final db = await database;
    final maps = await db.query('personal_bests',
        where: 'exercise_id = ?', whereArgs: [exerciseId]);
    return maps.map(PersonalBest.fromMap).toList();
  }

  Future<void> _updatePersonalBest(Database db, String exerciseId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final exerciseMaps = await db.query('exercises',
        where: 'id = ?', whereArgs: [exerciseId], limit: 1);
    if (exerciseMaps.isEmpty) return;

    final category = ExerciseCategory.values
        .byName(exerciseMaps.first['category'] as String);
    final recordMaps = await db.query('records',
        where: 'exercise_id = ? AND is_deleted = 0', whereArgs: [exerciseId]);

    await db.delete('personal_bests', where: 'exercise_id = ?', whereArgs: [exerciseId]);
    if (recordMaps.isEmpty) return;

    Map<String, dynamic>? best;
    PersonalBestType? pbType;

    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = recordMaps
            .where((r) => r['weight'] != null && (r['reps'] == null || (r['reps'] as num).toInt() == 1))
            .toList();
        if (oneRep.isEmpty) break;
        best = oneRep.reduce((a, b) =>
            (a['weight'] as num).toDouble() >= (b['weight'] as num).toDouble() ? a : b);
        pbType = PersonalBestType.maxWeight;

      case ExerciseCategory.running:
        final withTime = recordMaps.where((r) => r['duration_seconds'] != null).toList();
        if (withTime.isEmpty) break;
        best = withTime.reduce((a, b) =>
            (a['duration_seconds'] as num).toInt() <= (b['duration_seconds'] as num).toInt() ? a : b);
        pbType = PersonalBestType.bestTime;

      case ExerciseCategory.workout:
        final withTime = recordMaps.where((r) => r['duration_seconds'] != null).toList();
        if (withTime.isEmpty) break;
        best = withTime.reduce((a, b) =>
            (a['duration_seconds'] as num).toInt() <= (b['duration_seconds'] as num).toInt() ? a : b);
        pbType = PersonalBestType.bestTime;

      case ExerciseCategory.custom:
        break;
    }

    if (best == null || pbType == null) return;

    final pbValue = pbType == PersonalBestType.maxWeight
        ? (best['weight'] as num).toDouble()
        : (best['duration_seconds'] as num).toDouble();

    await db.insert('personal_bests', {
      'id': _uuid.v4(),
      'owner_id': 'local',
      'exercise_id': exerciseId,
      'source_record_id': best['id'],
      'pb_type': pbType.name,
      'value': pbValue,
      'achieved_at': best['performed_at'],
      'created_at': now,
      'updated_at': now,
      'sync_status': SyncStatus.pending.name,
    });
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
```

---

### Task 6: Rewrite providers

**Files:** `lib/providers/exercises_provider.dart`, `lib/providers/records_provider.dart`, Create `lib/providers/personal_best_provider.dart`

- [ ] Replace `exercises_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/exercise.dart';

class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async =>
      DatabaseHelper.instance.getExercises();

  Future<void> addExercise(String displayName, ExerciseCategory category) async {
    final current = state.valueOrNull ?? [];
    if (current.length >= 6) return;
    final exercise = Exercise.create(
      displayName: displayName,
      category: category,
      orderIndex: current.length,
    );
    await DatabaseHelper.instance.insertExercise(exercise);
    state = AsyncData([...current, exercise]);
  }

  Future<void> renameExercise(String id, String newName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = state.valueOrNull ?? [];
    final existing = current.firstWhere((e) => e.id == id);
    final updated = existing.copyWith(
      displayName: newName,
      normalizedName: normalizeExerciseName(newName),
      updatedAt: now,
    );
    await DatabaseHelper.instance.updateExercise(updated);
    state = AsyncData(current.map((e) => e.id == id ? updated : e).toList());
  }

  Future<void> deleteExercise(String id) async {
    await DatabaseHelper.instance.archiveExercise(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());
  }
}

final exercisesProvider =
    AsyncNotifierProvider<ExercisesNotifier, List<Exercise>>(
  ExercisesNotifier.new,
);
```

- [ ] Replace `records_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/record.dart';
import 'personal_best_provider.dart';

class RecordsNotifier extends FamilyAsyncNotifier<List<Record>, String> {
  @override
  Future<List<Record>> build(String exerciseId) async =>
      DatabaseHelper.instance.getRecordsForExercise(exerciseId);

  Future<Record> addRecord({
    required int performedAt,
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distance,
    String? note,
  }) async {
    final record = Record.create(
      exerciseId: arg,
      performedAt: performedAt,
      weight: weight,
      reps: reps,
      durationSeconds: durationSeconds,
      distance: distance,
      note: note,
    );
    await DatabaseHelper.instance.insertRecord(record);
    ref.invalidate(personalBestProvider(arg));
    final current = state.valueOrNull ?? [];
    final updated = [record, ...current]
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    state = AsyncData(updated);
    return record;
  }

  Future<void> deleteRecord(String id) async {
    await DatabaseHelper.instance.softDeleteRecord(id, arg);
    ref.invalidate(personalBestProvider(arg));
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((r) => r.id != id).toList());
  }
}

final recordsProvider =
    AsyncNotifierProvider.family<RecordsNotifier, List<Record>, String>(
  RecordsNotifier.new,
);
```

- [ ] Create `personal_best_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/personal_best.dart';

class PersonalBestNotifier
    extends FamilyAsyncNotifier<List<PersonalBest>, String> {
  @override
  Future<List<PersonalBest>> build(String exerciseId) async =>
      DatabaseHelper.instance.getPersonalBestsForExercise(exerciseId);
}

final personalBestProvider = AsyncNotifierProvider.family<
    PersonalBestNotifier, List<PersonalBest>, String>(
  PersonalBestNotifier.new,
);
```

---

### Task 7: Update AddExerciseSheet

**Files:** `lib/features/home/add_exercise_sheet.dart`

- [ ] Replace entire file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/exercises_provider.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _controller = TextEditingController();
  ExerciseCategory _selectedCategory = ExerciseCategory.strength;
  bool _saving = false;

  static const _categories = [
    (ExerciseCategory.strength, '무게', '스쿼트, 데드리프트 등'),
    (ExerciseCategory.running,  '러닝', '5km, 10km 달리기 등'),
    (ExerciseCategory.workout,  '와드', 'Fran, Murph 등'),
    (ExerciseCategory.custom,   '커스텀', '기타 운동'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운동 추가')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: '운동 이름',
                hintText: '예: Back Squat, 5km Run',
              ),
            ),
            const SizedBox(height: 24),
            const Text('운동 카테고리',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            ..._categories.map((t) => _CategoryTile(
                  category: t.$1,
                  label: t.$2,
                  description: t.$3,
                  selected: _selectedCategory == t.$1,
                  onTap: () => setState(() => _selectedCategory = t.$1),
                )),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('추가'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(exercisesProvider.notifier)
        .addExercise(name, _selectedCategory);
    if (mounted) Navigator.pop(context);
  }
}

class _CategoryTile extends StatelessWidget {
  final ExerciseCategory category;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category, required this.label, required this.description,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.separator,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: selected ? AppTheme.accent : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700)),
                  Text(description,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 8: Update ExerciseCard

**Files:** `lib/features/home/exercise_card.dart`

- [ ] Change all references: `exercise.name` → `exercise.displayName`, `exercise.type` → `exercise.category`, `exercise.id!` → `exercise.id`, `record.recordedAt` → `record.performedAt`, `record.value` → category-specific field. Full replacement:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import '../../providers/exercises_provider.dart';
import '../exercise_detail/exercise_detail_screen.dart';

class ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final bool editMode;
  const ExerciseCard({required this.exercise, this.editMode = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    final bestRecord = _getBestRecord(records, exercise.category);
    final displayValue = _formatBestValue(bestRecord, exercise, settings);
    final daysSince = _daysSince(records, exercise.category);

    return Slidable(
      key: ValueKey(exercise.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _showRenameDialog(context, ref),
            backgroundColor: AppTheme.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(
                      color: Color(0xFF007AFF), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.pencil, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 5),
                const Text('수정',
                    style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: AppTheme.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 5),
                const Text('삭제',
                    style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.card,
        child: InkWell(
          onTap: editMode
              ? null
              : () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailScreen(exercise: exercise),
                    )),
          splashColor: Colors.transparent,
          highlightColor: Colors.black.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (editMode)
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref),
                    child: Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30), shape: BoxShape.circle),
                      child: const Icon(Icons.remove, color: Colors.white, size: 14),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(exercise.displayName.toUpperCase(),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(exercise.category.label,
                                style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(displayValue,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(daysSince,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          if (bestRecord != null) ...[
                            const SizedBox(width: 6),
                            const Icon(CupertinoIcons.star_fill,
                                color: AppTheme.accent, size: 11),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${records.length}개',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_right,
                        color: AppTheme.separator, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Record? _getBestRecord(List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return null;
    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = records
            .where((r) => r.weight != null && (r.reps == null || r.reps == 1))
            .toList();
        if (oneRep.isEmpty) return null;
        return oneRep.reduce((a, b) =>
            (a.weight ?? 0) >= (b.weight ?? 0) ? a : b);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        final withTime = records.where((r) => r.durationSeconds != null).toList();
        if (withTime.isEmpty) return null;
        return withTime.reduce((a, b) =>
            (a.durationSeconds ?? 0) <= (b.durationSeconds ?? 0) ? a : b);
      case ExerciseCategory.custom:
        return records.first;
    }
  }

  String _formatBestValue(
      Record? best, Exercise exercise, UnitSettings? settings) {
    if (best == null) return '—';
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(
            best.weight ?? 0, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(best.durationSeconds ?? 0);
      case ExerciseCategory.custom:
        if (best.weight != null) {
          return UnitConverter.formatWeight(
              best.weight!, settings?.weightUnit ?? 'kg');
        }
        if (best.durationSeconds != null) {
          return UnitConverter.secondsToDisplay(best.durationSeconds!);
        }
        return '—';
    }
  }

  String _daysSince(List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return '기록 없음';
    if (category == ExerciseCategory.strength) {
      final oneRep = records
          .where((r) => r.weight != null && (r.reps == null || r.reps == 1))
          .toList();
      if (oneRep.isEmpty) return '기록 없음';
      final best = oneRep
          .reduce((a, b) => (a.weight ?? 0) >= (b.weight ?? 0) ? a : b);
      final diff = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(best.performedAt))
          .inDays;
      if (diff == 0) return '오늘 PR';
      return 'PR $diff일 전';
    }
    final last = DateTime.fromMillisecondsSinceEpoch(records.first.performedAt);
    final diff = DateTime.now().difference(last).inDays;
    if (diff == 0) return '오늘';
    return '$diff일 전';
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: exercise.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('운동 이름 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '운동 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(exercisesProvider.notifier)
                    .renameExercise(exercise.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('저장',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('운동 삭제'),
        content: Text("'${exercise.displayName}' 와(과) 모든 기록을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(exercisesProvider.notifier)
                  .deleteExercise(exercise.id);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );
  }
}
```

---

### Task 9: Update RecordInputScreen

**Files:** `lib/features/record_input/record_input_screen.dart`

- [ ] Replace entire file — category-based input fields, separate weight/reps/durationSeconds/distance:

```dart
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import 'pr_celebration_dialog.dart';

class RecordInputScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  const RecordInputScreen({required this.exercise, super.key});

  @override
  ConsumerState<RecordInputScreen> createState() => _RecordInputScreenState();
}

class _RecordInputScreenState extends ConsumerState<RecordInputScreen> {
  final _primaryController = TextEditingController();
  final _repsController = TextEditingController(text: '1');
  final _timeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  String? _localWeightUnit;
  String _distanceUnit = 'km';
  String _timeUnit = 'sec';

  @override
  void dispose() {
    _primaryController.dispose();
    _repsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final globalWeightUnit = settings?.weightUnit ?? 'kg';
    _localWeightUnit ??= globalWeightUnit;
    _distanceUnit = settings?.distanceUnit ?? 'km';
    final weightUnit = _localWeightUnit!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.displayName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DatePicker(
              selected: _selectedDate,
              onChanged: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 24),
            _buildInputFields(weightUnit),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(weightUnit),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields(String weightUnit) {
    switch (widget.exercise.category) {
      case ExerciseCategory.strength:
        return Column(
          children: [
            _UnitRow(
              label: '단위',
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: weightUnit,
                thumbColor: AppTheme.card,
                backgroundColor: AppTheme.background,
                children: {
                  'kg': _seg('kg', weightUnit == 'kg'),
                  'lbs': _seg('lbs', weightUnit == 'lbs'),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _localWeightUnit = v);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _NumField(
                    controller: _primaryController,
                    label: '무게',
                    suffix: weightUnit,
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
                  child: _NumField(
                    controller: _repsController,
                    label: '렙수',
                    suffix: '회',
                    decimal: false,
                  ),
                ),
              ],
            ),
          ],
        );

      case ExerciseCategory.running:
        return Column(
          children: [
            _NumField(
              controller: _primaryController,
              label: '거리',
              suffix: _distanceUnit,
              decimal: true,
            ),
            const SizedBox(height: 16),
            _UnitRow(
              label: '시간 단위',
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _timeUnit,
                thumbColor: AppTheme.card,
                backgroundColor: AppTheme.background,
                children: {
                  'sec': _seg('초', _timeUnit == 'sec'),
                  'min': _seg('분', _timeUnit == 'min'),
                  'hour': _seg('시간', _timeUnit == 'hour'),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _timeUnit = v);
                },
              ),
            ),
            const SizedBox(height: 16),
            _NumField(
              controller: _timeController,
              label: '시간 (선택)',
              suffix: _timeUnit == 'sec' ? '초' : _timeUnit == 'min' ? '분' : '시간',
              decimal: true,
            ),
          ],
        );

      case ExerciseCategory.workout:
        return Column(
          children: [
            _UnitRow(
              label: '단위',
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _timeUnit,
                thumbColor: AppTheme.card,
                backgroundColor: AppTheme.background,
                children: {
                  'sec': _seg('초', _timeUnit == 'sec'),
                  'min': _seg('분', _timeUnit == 'min'),
                  'hour': _seg('시간', _timeUnit == 'hour'),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _timeUnit = v);
                },
              ),
            ),
            const SizedBox(height: 16),
            _NumField(
              controller: _primaryController,
              label: '기록',
              suffix: _timeUnit == 'sec' ? '초' : _timeUnit == 'min' ? '분' : '시간',
              decimal: true,
            ),
          ],
        );

      case ExerciseCategory.custom:
        return _NumField(
          controller: _primaryController,
          label: '기록',
          suffix: '',
          decimal: true,
        );
    }
  }

  Widget _seg(String text, bool selected) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppTheme.accent : AppTheme.textPrimary,
            )),
      );

  int _toSeconds(double val, String unit) {
    switch (unit) {
      case 'min':  return (val * 60).round();
      case 'hour': return (val * 3600).round();
      default:     return val.round();
    }
  }

  Future<void> _save(String weightUnit) async {
    final raw = double.tryParse(_primaryController.text.trim());
    if (raw == null || raw <= 0) return;

    double? weight;
    int? reps;
    int? durationSeconds;
    double? distance;

    switch (widget.exercise.category) {
      case ExerciseCategory.strength:
        weight = weightUnit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
        reps = max(1, int.tryParse(_repsController.text.trim()) ?? 1);

      case ExerciseCategory.running:
        distance = _distanceUnit == 'mi' ? UnitConverter.miToKm(raw) : raw;
        final rawTime = double.tryParse(_timeController.text.trim());
        if (rawTime != null && rawTime > 0) {
          durationSeconds = _toSeconds(rawTime, _timeUnit);
        }

      case ExerciseCategory.workout:
        durationSeconds = _toSeconds(raw, _timeUnit);

      case ExerciseCategory.custom:
        weight = raw;
    }

    setState(() => _saving = true);

    final currentRecords =
        ref.read(recordsProvider(widget.exercise.id)).valueOrNull ?? [];
    final previousBest =
        _getPreviousBest(currentRecords, widget.exercise.category);

    await ref.read(recordsProvider(widget.exercise.id).notifier).addRecord(
          performedAt: _selectedDate.millisecondsSinceEpoch,
          weight: weight,
          reps: reps,
          durationSeconds: durationSeconds,
          distance: distance,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    final newBestValue = weight ?? durationSeconds?.toDouble() ?? distance;
    final isPb = _isPb(newBestValue, previousBest, widget.exercise.category, reps);
    if (isPb && newBestValue != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PRCelebrationDialog(
          exercise: widget.exercise,
          newValue: newBestValue,
          previousBest: previousBest,
          recordedDate: _selectedDate,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  double? _getPreviousBest(List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return null;
    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = records
            .where((r) => r.weight != null && (r.reps == null || r.reps == 1))
            .toList();
        if (oneRep.isEmpty) return null;
        return oneRep.map((r) => r.weight!).reduce(max);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        final withTime = records.where((r) => r.durationSeconds != null).toList();
        if (withTime.isEmpty) return null;
        return withTime.map((r) => r.durationSeconds!.toDouble()).reduce(min);
      case ExerciseCategory.custom:
        return null;
    }
  }

  bool _isPb(double? newValue, double? previousBest,
      ExerciseCategory category, int? reps) {
    if (newValue == null) return false;
    if (category == ExerciseCategory.strength && (reps ?? 1) != 1) return false;
    if (previousBest == null) return true;
    switch (category) {
      case ExerciseCategory.strength: return newValue > previousBest;
      case ExerciseCategory.running:
      case ExerciseCategory.workout:  return newValue < previousBest;
      case ExerciseCategory.custom:   return false;
    }
  }
}

class _UnitRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _UnitRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5)),
        const Spacer(),
        child,
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  const _NumField(
      {required this.controller,
      required this.label,
      required this.suffix,
      required this.decimal});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isEmpty ? null : suffix,
        suffixStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  const _DatePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label =
        '${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.calendar, color: AppTheme.accent, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right,
                color: AppTheme.textSecondary, size: 14),
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
              color: AppTheme.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      onChanged(temp);
                      Navigator.pop(context);
                    },
                    child: const Text('완료',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator),
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
```

---

### Task 10: Update ExerciseDetailScreen

**Files:** `lib/features/exercise_detail/exercise_detail_screen.dart`

- [ ] Replace `exercise.name` → `exercise.displayName`, `exercise.type` → `exercise.category`, `exercise.id!` → `exercise.id`, `record.value` → field-specific, `record.recordedAt` → `record.performedAt`, `r.id!` → `r.id`. Full replacement:

```dart
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import '../home/one_rm_panel.dart';
import '../record_input/record_input_screen.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({required this.exercise, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final bestValue = _getBestValue(records, exercise.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.displayName),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => RecordInputScreen(exercise: exercise))),
            child: const Text('기록 추가',
                style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _StatsCard(
                    exercise: exercise,
                    records: records,
                    settings: settings,
                    bestValue: bestValue,
                  ),
                ),
                if (exercise.category == ExerciseCategory.strength) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  SliverToBoxAdapter(child: OneRmPanel(exercise: exercise)),
                ],
                const SliverToBoxAdapter(child: _SectionLabel('기록 히스토리')),
                if (records.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Center(
                        child: Text('아직 기록이 없어요',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 15)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final r = records[i];
                          return _HistoryTile(
                            record: r,
                            exercise: exercise,
                            isBest: _isBestRecord(r, records, exercise.category),
                            settings: settings,
                            isLast: i == records.length - 1,
                            onDelete: () => ref
                                .read(recordsProvider(exercise.id).notifier)
                                .deleteRecord(r.id),
                          );
                        },
                        childCount: records.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _getBestValue(List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return null;
    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = records
            .where((r) => r.weight != null && (r.reps == null || r.reps == 1))
            .toList();
        if (oneRep.isEmpty) return null;
        return oneRep.map((r) => r.weight!).reduce(max);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        final withTime = records.where((r) => r.durationSeconds != null).toList();
        if (withTime.isEmpty) return null;
        return withTime.map((r) => r.durationSeconds!.toDouble()).reduce(min);
      case ExerciseCategory.custom:
        return null;
    }
  }

  bool _isBestRecord(
      Record r, List<Record> all, ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        if (r.weight == null) return false;
        final oneRep = all
            .where((x) => x.weight != null && (x.reps == null || x.reps == 1))
            .toList();
        if (oneRep.isEmpty) return false;
        final best = oneRep.map((x) => x.weight!).reduce(max);
        return r.weight == best && (r.reps == null || r.reps == 1);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        if (r.durationSeconds == null) return false;
        final withTime =
            all.where((x) => x.durationSeconds != null).toList();
        if (withTime.isEmpty) return false;
        final best =
            withTime.map((x) => x.durationSeconds!).reduce(min);
        return r.durationSeconds == best;
      case ExerciseCategory.custom:
        return false;
    }
  }
}

class _StatsCard extends StatelessWidget {
  final Exercise exercise;
  final List<Record> records;
  final UnitSettings? settings;
  final double? bestValue;

  const _StatsCard({
    required this.exercise, required this.records,
    required this.settings, required this.bestValue,
  });

  @override
  Widget build(BuildContext context) {
    final displayBest = _formatValue(bestValue);
    final daysSince = _daysSince();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.card, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(exercise.category.label.toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('최고 기록',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(displayBest,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(daysSince,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatValue(double? v) {
    if (v == null) return '—';
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(v, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(v.toInt());
      case ExerciseCategory.custom:
        return v.toStringAsFixed(1);
    }
  }

  String _daysSince() {
    if (records.isEmpty) return '기록 없음';
    if (exercise.category == ExerciseCategory.strength) {
      final oneRep = records
          .where((r) => r.weight != null && (r.reps == null || r.reps == 1))
          .toList();
      if (oneRep.isEmpty) return '기록 없음';
      final best =
          oneRep.reduce((a, b) => (a.weight ?? 0) >= (b.weight ?? 0) ? a : b);
      final diff = DateTime.now()
          .difference(
              DateTime.fromMillisecondsSinceEpoch(best.performedAt))
          .inDays;
      if (diff == 0) return 'PR 오늘 갱신됨';
      return 'PR $diff일 전 갱신';
    }
    final last =
        DateTime.fromMillisecondsSinceEpoch(records.first.performedAt);
    final diff = DateTime.now().difference(last).inDays;
    if (diff == 0) return '오늘 업데이트됨';
    return '$diff일 전';
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5)),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Record record;
  final Exercise exercise;
  final bool isBest;
  final UnitSettings? settings;
  final bool isLast;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.record, required this.exercise, required this.isBest,
    required this.settings, required this.isLast, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(record.performedAt);
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isBest ? 10 : 0),
        bottom: Radius.circular(isLast ? 10 : 0),
      ),
      child: Dismissible(
        key: Key('record_${record.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
          child: const Icon(CupertinoIcons.trash,
              color: Color(0xFFFF3B30), size: 18),
        ),
        confirmDismiss: (_) async => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('기록 삭제'),
            content: const Text('이 기록을 삭제할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제',
                    style: TextStyle(color: Color(0xFFFF3B30))),
              ),
            ],
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: Container(
          color: isBest
              ? AppTheme.accent.withValues(alpha: 0.04)
              : AppTheme.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(_formatValue(),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (isBest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('PB',
                            style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.separator,
                    indent: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue() {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        final w = UnitConverter.formatWeight(
            record.weight ?? 0, settings?.weightUnit ?? 'kg');
        return (record.reps != null && record.reps! > 1)
            ? '$w × ${record.reps}회'
            : w;
      case ExerciseCategory.running:
        final parts = <String>[];
        if (record.distance != null) {
          parts.add(UnitConverter.formatDistance(
              record.distance!, settings?.distanceUnit ?? 'km'));
        }
        if (record.durationSeconds != null) {
          parts.add(UnitConverter.secondsToDisplay(record.durationSeconds!));
        }
        return parts.join('  ');
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(record.durationSeconds ?? 0);
      case ExerciseCategory.custom:
        if (record.weight != null) {
          return UnitConverter.formatWeight(
              record.weight!, settings?.weightUnit ?? 'kg');
        }
        if (record.durationSeconds != null) {
          return UnitConverter.secondsToDisplay(record.durationSeconds!);
        }
        return '—';
    }
  }
}
```

---

### Task 11: Update OneRmPanel

**Files:** `lib/features/home/one_rm_panel.dart`

- [ ] Change `exercise.id!` → `exercise.id`, `records.where((r) => r.reps == 1)` → `records.where((r) => r.weight != null && (r.reps == null || r.reps == 1))`, `r.value` → `r.weight!`. Lines to update:

Line 42: `ref.watch(recordsProvider(widget.exercise.id!))` → `ref.watch(recordsProvider(widget.exercise.id))`  
Line 44: `ref.watch(unitSettingsProvider)...` (no change)  
Lines 47–49: replace bestKg calculation:
```dart
double? bestKg;
final oneReps = records
    .where((r) => r.weight != null && (r.reps == null || r.reps == 1))
    .toList();
if (oneReps.isNotEmpty) {
  bestKg = oneReps.map((r) => r.weight!).reduce((a, b) => a > b ? a : b);
}
```
Line 77: `_showTable(context, bestKg!, unit)` (no change, bestKg is still double?)

---

### Task 12: Update PRCelebrationDialog

**Files:** `lib/features/record_input/pr_celebration_dialog.dart`

- [ ] Change `exercise.name` → `exercise.displayName` (line 58)
- [ ] Change `exercise.type` → `exercise.category` (lines 29, 30, 136, 148)
- [ ] Update `_formatValue` switch to use `ExerciseCategory`:

```dart
String _formatValue(double value, ExerciseCategory category,
    String weightUnit, String distanceUnit) {
  switch (category) {
    case ExerciseCategory.strength:
      return UnitConverter.formatWeight(value, weightUnit);
    case ExerciseCategory.running:
    case ExerciseCategory.workout:
      return UnitConverter.secondsToDisplay(value.toInt());
    case ExerciseCategory.custom:
      return value.toStringAsFixed(1);
  }
}

String? _formatDiff(double newVal, double? prev, ExerciseCategory category,
    String weightUnit, String distanceUnit) {
  if (prev == null) return null;
  switch (category) {
    case ExerciseCategory.strength:
      return UnitConverter.formatDiffWeight(newVal - prev, weightUnit);
    case ExerciseCategory.running:
    case ExerciseCategory.workout:
      return UnitConverter.formatDiffTime((newVal - prev).toInt());
    case ExerciseCategory.custom:
      return null;
  }
}
```

---

### Task 13: Update HistoryScreen + Export files

**Files:** `lib/features/history/history_screen.dart`, `lib/features/export/export_screen.dart`, `lib/features/export/clean_frame.dart`, `lib/features/export/rough_frame.dart`

- [ ] `history_screen.dart`: Change `exercise.id!` → `exercise.id`, `exercise.name` → `exercise.displayName`, `exercise.type` → `exercise.category`, `record.recordedAt` → `record.performedAt`, `record.value` → `_valueForRecord(r, exercise.category)`, `r.id!` → `r.id`

- [ ] `export_screen.dart`: Change `exercise.name` → `exercise.displayName` (line 136 subject)

- [ ] `clean_frame.dart`: Change `exercise.name` → `exercise.displayName`, `exercise.type` → `exercise.category`, update `_formatValue` switch to `ExerciseCategory`

- [ ] `rough_frame.dart`: Same changes as clean_frame.dart

---

### Task 14: Build & verify

- [ ] Run `flutter build ios --no-codesign` (or `flutter analyze`)
- [ ] Fix any remaining type errors
- [ ] Run app on simulator, create 1 exercise, add 1 record, confirm PB dialog shows
- [ ] Commit:

```bash
git add -A
git commit -m "feat: DB Foundation — UUID PKs, expanded Record model, PersonalBest/SyncTask tables, soft delete"
```
