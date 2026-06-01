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
      join(dbPath, 'pbpr.db'),
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

  Future<List<PersonalBest>> getPersonalBestsForExercise(
      String exerciseId) async {
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

    await db.delete('personal_bests',
        where: 'exercise_id = ?', whereArgs: [exerciseId]);
    if (recordMaps.isEmpty) return;

    Map<String, dynamic>? best;
    PersonalBestType? pbType;

    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = recordMaps
            .where((r) =>
                r['weight'] != null &&
                (r['reps'] == null || (r['reps'] as num).toInt() == 1))
            .toList();
        if (oneRep.isEmpty) break;
        best = oneRep.reduce((a, b) =>
            (a['weight'] as num).toDouble() >= (b['weight'] as num).toDouble()
                ? a
                : b);
        pbType = PersonalBestType.maxWeight;

      case ExerciseCategory.running:
        final withTime =
            recordMaps.where((r) => r['duration_seconds'] != null).toList();
        if (withTime.isEmpty) break;
        best = withTime.reduce((a, b) =>
            (a['duration_seconds'] as num).toInt() <=
                    (b['duration_seconds'] as num).toInt()
                ? a
                : b);
        pbType = PersonalBestType.bestTime;

      case ExerciseCategory.workout:
        final withTime =
            recordMaps.where((r) => r['duration_seconds'] != null).toList();
        if (withTime.isEmpty) break;
        best = withTime.reduce((a, b) =>
            (a['duration_seconds'] as num).toInt() <=
                    (b['duration_seconds'] as num).toInt()
                ? a
                : b);
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
