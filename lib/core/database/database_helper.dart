import 'package:path/path.dart' hide normalize;
import 'package:sqflite/sqflite.dart';
import '../models/exercise.dart';
import '../models/health_import.dart';
import '../models/note.dart';
import '../models/record.dart';
import '../utils/normalize.dart';
import '../../domain/models/category.dart';
import '../../domain/models/public_record.dart';

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
      version: 25,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await _addColumnIfMissing(db, 'exercises', 'best_type', 'TEXT');
        await _addColumnIfMissing(
            db, 'exercises', 'base_unit', "TEXT NOT NULL DEFAULT 'kg'");
        await _addColumnIfMissing(db, 'exercises', 'time_cap', 'INTEGER');
        await _addColumnIfMissing(db, 'records', 'time_cap', 'INTEGER');
        await _addColumnIfMissing(db, 'exercises', 'pb_higher_is_better',
            'INTEGER NOT NULL DEFAULT 1');
        await _addColumnIfMissing(db, 'exercises', 'exercise_type',
            "TEXT NOT NULL DEFAULT 'record'");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await _migrate(db, oldVersion, newVersion);
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        // Version conflict — drop all tables and recreate from scratch
        await db.execute('PRAGMA foreign_keys = OFF');
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        );
        for (final t in tables) {
          await db.execute('DROP TABLE IF EXISTS ${t['name']}');
        }
        await db.execute('PRAGMA foreign_keys = ON');
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
    await db.execute('''
      CREATE TABLE exercises (
        id               TEXT PRIMARY KEY,
        owner_id         TEXT,
        display_name     TEXT NOT NULL,
        normalized_name  TEXT NOT NULL,
        category         TEXT NOT NULL DEFAULT 'strength',
        category_id      TEXT REFERENCES categories(id),
        record_type      TEXT,
        best_type        TEXT,
        base_unit              TEXT NOT NULL DEFAULT 'kg',
        pb_higher_is_better   INTEGER NOT NULL DEFAULT 1,
        exercise_type          TEXT NOT NULL DEFAULT 'record',
        time_cap               INTEGER,
        is_system_preset       INTEGER NOT NULL DEFAULT 0,
        visibility       TEXT NOT NULL DEFAULT 'private',
        is_archived      INTEGER NOT NULL DEFAULT 0,
        has_pr_baseline  INTEGER NOT NULL DEFAULT 0,
        order_index      INTEGER NOT NULL DEFAULT 0,
        created_at       INTEGER NOT NULL,
        updated_at       INTEGER NOT NULL,
        sync_status      TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    await db.execute('''
      CREATE TABLE records (
        id               TEXT PRIMARY KEY,
        owner_id         TEXT,
        exercise_id      TEXT NOT NULL REFERENCES exercises(id),
        performed_at     INTEGER NOT NULL,
        weight           REAL,
        weight_unit      TEXT NOT NULL DEFAULT 'kg',
        reps             INTEGER,
        rounds           INTEGER,
        duration_seconds INTEGER,
        duration_minutes INTEGER,
        distance         REAL,
        distance_unit    TEXT NOT NULL DEFAULT 'km',
        note             TEXT,
        metadata_json    TEXT,
        is_deleted       INTEGER NOT NULL DEFAULT 0,
        is_pr_candidate  INTEGER NOT NULL DEFAULT 1,
        time_cap         INTEGER,
        created_at       INTEGER NOT NULL,
        updated_at       INTEGER NOT NULL,
        sync_status      TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    await db.execute('''
      CREATE TABLE public_records (
        exercise_id   TEXT PRIMARY KEY REFERENCES exercises(id) ON DELETE CASCADE,
        display_order INTEGER NOT NULL DEFAULT 0,
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE health_imports (
        id          TEXT PRIMARY KEY,
        record_id   TEXT NOT NULL,
        imported_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE notes (
        id           TEXT PRIMARY KEY,
        performed_on INTEGER NOT NULL,
        title        TEXT NOT NULL DEFAULT '',
        body         TEXT NOT NULL DEFAULT '',
        sort_order   INTEGER NOT NULL DEFAULT 0,
        is_deleted   INTEGER NOT NULL DEFAULT 0,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL
      )
    ''');
    await _createIndexes(db);
    await _seedCategories(db);
    await _seedExercises(db);
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // categories table must exist before seeding
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY, name TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');

      await _seedCategories(db);

      // exercises: add new columns (category must exist before record_type UPDATE references it)
      await _addColumnIfMissing(db, 'exercises', 'category', "TEXT DEFAULT 'strength'");
      await _addColumnIfMissing(db, 'exercises', 'category_id', 'TEXT');
      await _addColumnIfMissing(db, 'exercises', 'record_type', "TEXT DEFAULT 'weight'");
      await _addColumnIfMissing(db, 'exercises', 'is_system_preset', 'INTEGER NOT NULL DEFAULT 0');

      // Populate record_type and category_id from legacy category
      await db.execute("""
        UPDATE exercises SET record_type = CASE category
          WHEN 'strength' THEN 'weight'
          WHEN 'running'  THEN 'etc'
          WHEN 'workout'  THEN 'forTime'
          ELSE 'weight'
        END WHERE record_type IS NULL OR record_type = 'weight'
      """);
      await db.execute("""
        UPDATE exercises SET category_id = CASE category
          WHEN 'strength' THEN '${Category.weightliftingId}'
          WHEN 'running'  THEN '${Category.runId}'
          WHEN 'workout'  THEN '${Category.wodId}'
          WHEN 'custom'   THEN '${Category.customId}'
          ELSE '${Category.customId}'
        END WHERE category_id IS NULL
      """);

      // records: add new columns
      await _addColumnIfMissing(db, 'records', 'weight_unit', "TEXT NOT NULL DEFAULT 'kg'");
      await _addColumnIfMissing(db, 'records', 'rounds', 'INTEGER');
      await _addColumnIfMissing(db, 'records', 'distance_unit', "TEXT NOT NULL DEFAULT 'km'");
      await _addColumnIfMissing(db, 'records', 'metadata_json', 'TEXT');

      // public_records table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS public_records (
          exercise_id TEXT PRIMARY KEY REFERENCES exercises(id) ON DELETE CASCADE,
          display_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
        )
      ''');

      // health_imports table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS health_imports (
          id          TEXT PRIMARY KEY,
          record_id   TEXT NOT NULL,
          imported_at INTEGER NOT NULL
        )
      ''');

      await _createIndexes(db);
    }

    if (oldVersion < 6) {
      // Remove NOT NULL constraint from owner_id in records and exercises.
      // SQLite doesn't support ALTER COLUMN, so we recreate both tables.
      await db.execute('PRAGMA foreign_keys = OFF');

      await db.execute('''
        CREATE TABLE records_v6 (
          id               TEXT PRIMARY KEY,
          owner_id         TEXT,
          exercise_id      TEXT NOT NULL REFERENCES exercises(id),
          performed_at     INTEGER NOT NULL,
          weight           REAL,
          weight_unit      TEXT NOT NULL DEFAULT 'kg',
          reps             INTEGER,
          rounds           INTEGER,
          duration_seconds INTEGER,
          distance         REAL,
          distance_unit    TEXT NOT NULL DEFAULT 'km',
          note             TEXT,
          metadata_json    TEXT,
          is_deleted       INTEGER NOT NULL DEFAULT 0,
          created_at       INTEGER NOT NULL,
          updated_at       INTEGER NOT NULL,
          sync_status      TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      await db.execute('''
        INSERT INTO records_v6
          (id, owner_id, exercise_id, performed_at, weight, weight_unit,
           reps, rounds, duration_seconds, distance, distance_unit,
           note, metadata_json, is_deleted, created_at, updated_at, sync_status)
        SELECT id, owner_id, exercise_id, performed_at, weight, weight_unit,
               reps, rounds, duration_seconds, distance, distance_unit,
               note, metadata_json, is_deleted, created_at, updated_at, sync_status
        FROM records
      ''');
      await db.execute('DROP TABLE records');
      await db.execute('ALTER TABLE records_v6 RENAME TO records');

      await db.execute('''
        CREATE TABLE exercises_v6 (
          id               TEXT PRIMARY KEY,
          owner_id         TEXT,
          display_name     TEXT NOT NULL,
          normalized_name  TEXT NOT NULL,
          category         TEXT NOT NULL DEFAULT 'strength',
          category_id      TEXT REFERENCES categories(id),
          record_type      TEXT NOT NULL DEFAULT 'weight',
          is_system_preset INTEGER NOT NULL DEFAULT 0,
          visibility       TEXT NOT NULL DEFAULT 'private',
          is_archived      INTEGER NOT NULL DEFAULT 0,
          order_index      INTEGER NOT NULL DEFAULT 0,
          created_at       INTEGER NOT NULL,
          updated_at       INTEGER NOT NULL,
          sync_status      TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      await db.execute('''
        INSERT INTO exercises_v6
          (id, owner_id, display_name, normalized_name, category, category_id,
           record_type, is_system_preset, visibility, is_archived, order_index,
           created_at, updated_at, sync_status)
        SELECT id, owner_id, display_name, normalized_name, category, category_id,
               record_type, is_system_preset, visibility, is_archived, order_index,
               created_at, updated_at, sync_status
        FROM exercises
      ''');
      await db.execute('DROP TABLE exercises');
      await db.execute('ALTER TABLE exercises_v6 RENAME TO exercises');

      await db.execute('PRAGMA foreign_keys = ON');
      await _createIndexes(db);
    }

    if (oldVersion < 7) {
      // Make exercises.record_type nullable (remove NOT NULL DEFAULT 'weight').
      // SQLite doesn't support ALTER COLUMN — recreate the table.
      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('''
        CREATE TABLE exercises_v7 (
          id               TEXT PRIMARY KEY,
          owner_id         TEXT,
          display_name     TEXT NOT NULL,
          normalized_name  TEXT NOT NULL,
          category         TEXT NOT NULL DEFAULT 'strength',
          category_id      TEXT REFERENCES categories(id),
          record_type      TEXT,
          is_system_preset INTEGER NOT NULL DEFAULT 0,
          visibility       TEXT NOT NULL DEFAULT 'private',
          is_archived      INTEGER NOT NULL DEFAULT 0,
          order_index      INTEGER NOT NULL DEFAULT 0,
          created_at       INTEGER NOT NULL,
          updated_at       INTEGER NOT NULL,
          sync_status      TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      await db.execute('''
        INSERT INTO exercises_v7
          (id, owner_id, display_name, normalized_name, category, category_id,
           record_type, is_system_preset, visibility, is_archived, order_index,
           created_at, updated_at, sync_status)
        SELECT id, owner_id, display_name, normalized_name, category, category_id,
               record_type, is_system_preset, visibility, is_archived, order_index,
               created_at, updated_at, sync_status
        FROM exercises
      ''');
      await db.execute('DROP TABLE exercises');
      await db.execute('ALTER TABLE exercises_v7 RENAME TO exercises');
      await db.execute('PRAGMA foreign_keys = ON');
      await _createIndexes(db);
    }

    if (oldVersion < 8) {
      // Remove preset exercises that have no user records.
      // Presets with records are kept so existing user data is not lost.
      await db.execute('''
        DELETE FROM exercises
        WHERE id LIKE 'preset-ex-%'
          AND is_system_preset = 1
          AND id NOT IN (
            SELECT DISTINCT exercise_id FROM records WHERE is_deleted = 0
          )
      ''');
    }

    if (oldVersion < 9) {
      await _addColumnIfMissing(
          db, 'records', 'is_pr_candidate', 'INTEGER NOT NULL DEFAULT 1');
    }

    if (oldVersion < 10) {
      await _addColumnIfMissing(
          db, 'exercises', 'base_unit', "TEXT NOT NULL DEFAULT 'kg'");
    }

    if (oldVersion < 12) {
      await _addColumnIfMissing(
          db, 'exercises', 'has_pr_baseline', 'INTEGER NOT NULL DEFAULT 0');
      // Exercises that already have active records implicitly have a baseline.
      await db.execute('''
        UPDATE exercises SET has_pr_baseline = 1
        WHERE id IN (
          SELECT DISTINCT exercise_id FROM records WHERE is_deleted = 0
        )
      ''');
    }

    if (oldVersion < 13) {
      // Add color column; existing rows default to 'gray'.
      await _addColumnIfMissing(
          db, 'categories', 'color', "TEXT NOT NULL DEFAULT 'gray'");
      // Set correct colors for the legacy preset IDs that existing users have.
      await db.execute(
          "UPDATE categories SET color = 'amber' WHERE id = '${Category.weightliftingId}'");
      await db.execute(
          "UPDATE categories SET color = 'blue'  WHERE id = '${Category.runId}'");
      await db.execute(
          "UPDATE categories SET color = 'green' WHERE id = '${Category.wodId}'");
      // 'preset-category-custom' keeps 'gray' — already correct from the DEFAULT.
    }

    if (oldVersion < 14) {
      // Recompute normalized_name for all exercises using the Unicode-safe
      // normalize() — the old [^a-z0-9\s] regex collapsed all Korean (and any
      // other non-ASCII) names to "", causing false-positive duplicate detection
      // for every Korean exercise name.
      final rows = await db.query(
        'exercises',
        columns: ['id', 'display_name', 'normalized_name'],
      );
      final collisions = <String>[];
      for (final row in rows) {
        final id          = row['id']              as String;
        final displayName = row['display_name']    as String;
        final currentNorm = row['normalized_name'] as String;
        final newNorm     = normalize(displayName);

        if (newNorm == currentNorm) continue;

        // Before updating, check whether another exercise already owns newNorm.
        // We check explicitly (rather than relying on ConflictAlgorithm.ignore)
        // so collisions are surfaced rather than silently dropped.
        final ownerRows = await db.query(
          'exercises',
          columns: ['id', 'display_name'],
          where:     'normalized_name = ? AND id != ?',
          whereArgs: [newNorm, id],
        );
        if (ownerRows.isNotEmpty) {
          final owner = ownerRows.first;
          final msg =
              '[Migration v14] COLLISION — skipped: '
              '"$displayName" (id=$id) wants normalized="$newNorm" '
              'but it is already owned by '
              '"${owner['display_name']}" (id=${owner['id']})';
          collisions.add(msg);
          continue;
        }

        await db.update(
          'exercises',
          {'normalized_name': newNorm},
          where:     'id = ?',
          whereArgs: [id],
        );
      }
    }

    if (oldVersion < 15) {
      await _addColumnIfMissing(db, 'records', 'duration_minutes', 'INTEGER');
    }

    if (oldVersion < 16) {
      await db.execute(
          "UPDATE exercises SET record_type = 'etc' WHERE record_type = 'distance'");
    }

    if (oldVersion < 18) {
      await _addColumnIfMissing(db, 'exercises', 'time_cap', 'INTEGER');
    }

    if (oldVersion < 17) {
      // Ensure Uncategorized exists (new fallback category).
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.execute('''
        INSERT OR IGNORE INTO categories
          (id, name, color, sort_order, created_at, updated_at, sync_status)
        VALUES
          ('${Category.uncategorizedId}', 'Uncategorized', 'gray', ${Category.uncategorizedDefaultSortOrder}, $now, $now, 'pending')
      ''');
      // Move exercises with null or orphaned category_id to Uncategorized.
      await db.execute('''
        UPDATE exercises
        SET category_id = '${Category.uncategorizedId}'
        WHERE category_id IS NULL
           OR category_id NOT IN (SELECT id FROM categories)
      ''');
    }

    if (oldVersion < 19) {
      await _addColumnIfMissing(db, 'records', 'time_cap', 'INTEGER');
    }

    if (oldVersion < 20) {
      // Replace the flat unique index with a partial one so that archived
      // exercises no longer block re-creation of a same-named active exercise.
      await db.execute('DROP INDEX IF EXISTS idx_exercises_normalized_name');
      await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_exercises_normalized_name ON exercises(normalized_name) WHERE is_archived = 0');
    }

    if (oldVersion < 21) {
      // Correct Uncategorized color key from 'brown' (dev-cycle mistake) to 'gray'.
      await db.execute(
        "UPDATE categories SET color = 'gray' WHERE id = '${Category.uncategorizedId}' AND color = 'brown'",
      );
    }

    if (oldVersion < 22) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes (
          id           TEXT PRIMARY KEY,
          performed_on INTEGER NOT NULL,
          title        TEXT NOT NULL DEFAULT '',
          body         TEXT NOT NULL DEFAULT '',
          sort_order   INTEGER NOT NULL DEFAULT 0,
          is_deleted   INTEGER NOT NULL DEFAULT 0,
          created_at   INTEGER NOT NULL,
          updated_at   INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_performed_on ON notes(performed_on)',
      );
    }

    if (oldVersion < 23) {
      await _addColumnIfMissing(db, 'exercises', 'pb_higher_is_better',
          'INTEGER NOT NULL DEFAULT 1');
    }

    if (oldVersion < 24) {
      await _addColumnIfMissing(db, 'exercises', 'exercise_type',
          "TEXT NOT NULL DEFAULT 'record'");
    }

    if (oldVersion < 25) {
      // Migrate legacy category color keys to the new palette.
      // Uncategorized (color = 'gray') is intentionally excluded.
      await db.execute("UPDATE categories SET color = 'crimson' WHERE color = 'red'");
      await db.execute("UPDATE categories SET color = 'rust'    WHERE color = 'pink'");
      await db.execute("UPDATE categories SET color = 'gold'    WHERE color = 'amber'");
      await db.execute("UPDATE categories SET color = 'teal'    WHERE color = 'purple'");
      await db.execute("UPDATE categories SET color = 'ocean'   WHERE color = 'blue'");
      await db.execute("UPDATE categories SET color = 'olive'   WHERE color = 'green'");
      await db.execute("UPDATE categories SET color = 'forest'  WHERE color = 'brown'");
    }
  }

  Future<void> _addColumnIfMissing(
      Database db, String table, String column, String definition) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_records_exercise_id ON records(exercise_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_records_performed_at ON records(performed_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_records_is_deleted ON records(is_deleted)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_exercises_category_id ON exercises(category_id)');
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_exercises_normalized_name ON exercises(normalized_name) WHERE is_archived = 0');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_public_records_display_order ON public_records(display_order)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_performed_on ON notes(performed_on)');
  }

  Future<void> _seedCategories(Database db) async {
    // New installs: only Uncategorized is seeded.
    for (final cat in Category.presets) {
      await db.insert('categories', cat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedExercises(Database db) async {}

  // ── EXERCISES ──────────────────────────────────────────────────

  Future<void> insertExercise(Exercise exercise) async {
    final db = await database;
    await db.insert('exercises', exercise.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
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

  Future<void> updateExerciseRecordType(String id, RecordType rt) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'exercises',
      {'record_type': rt.name, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Exercise?> findExerciseByNormalizedName(String normalizedName) async {
    final db = await database;
    final maps = await db.query(
      'exercises',
      where: 'normalized_name = ?',
      whereArgs: [normalizedName],
      orderBy: 'is_archived ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<void> unarchiveExercise(String id) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'exercises',
      {'is_archived': 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setPrBaseline(String id) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'exercises',
      {'has_pr_baseline': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> archiveExercise(String id) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update(
          'exercises', {'is_archived': 1, 'updated_at': now},
          where: 'id = ?', whereArgs: [id]);
      await txn.update(
          'records', {'is_deleted': 1, 'updated_at': now},
          where: 'exercise_id = ? AND is_deleted = 0', whereArgs: [id]);
    });
  }

  // ── RECORDS ────────────────────────────────────────────────────

  Future<void> insertRecord(Record record) async {
    final db = await database;
    // DEBUG: verify exercise exists before insert
    final exerciseRows = await db.query(
      'exercises',
      columns: ['id', 'is_archived'],
      where: 'id = ?',
      whereArgs: [record.exerciseId],
      limit: 1,
    );
    if (exerciseRows.isEmpty) {
      throw StateError(
        'insertRecord: exercise not found in DB — exerciseId=${record.exerciseId}',
      );
    }
    await db.insert('records', record.toMap());
  }

  Future<void> updateRecord(Record record) async {
    final db = await database;
    await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
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

  Future<List<Record>> getRecentRecords({int limit = 30}) async {
    final db = await database;
    final maps = await db.query(
      'records',
      where: 'is_deleted = 0',
      orderBy: 'performed_at DESC',
      limit: limit,
    );
    return maps.map(Record.fromMap).toList();
  }

  Future<Record?> getRecordById(String recordId) async {
    final db = await database;
    final maps = await db.query(
      'records',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [recordId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Record.fromMap(maps.first);
  }

  Future<void> softDeleteRecord(String recordId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'records',
      {'is_deleted': 1, 'updated_at': now, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  // ── CATEGORIES ─────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'sort_order ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<void> insertCategory(Category cat) async {
    final db = await database;
    await db.insert('categories', cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(Category cat) async {
    final db = await database;
    await db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.update('exercises', {'category_id': Category.uncategorizedId},
        where: 'category_id = ?', whereArgs: [id]);
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── PUBLIC RECORDS ─────────────────────────────────────────────

  Future<List<PublicRecord>> getPublicRecords() async {
    final db = await database;
    final maps =
        await db.query('public_records', orderBy: 'display_order ASC');
    return maps.map(PublicRecord.fromMap).toList();
  }

  Future<void> insertPublicRecord(PublicRecord pr) async {
    final db = await database;
    await db.insert('public_records', pr.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePublicRecord(String exerciseId) async {
    final db = await database;
    await db.delete('public_records',
        where: 'exercise_id = ?', whereArgs: [exerciseId]);
  }

  Future<int> countPublicRecords() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as c FROM public_records');
    return (result.first['c'] as num).toInt();
  }

  // ── HEALTH IMPORTS ─────────────────────────────────────────────

  // TODO: Record 수 증가 시 healthKitWorkoutId 전용 컬럼 분리 검토
  Future<bool> hasHealthKitWorkout(String workoutId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT 1 FROM records WHERE is_deleted = 0 '
      'AND metadata_json LIKE ? LIMIT 1',
      ['%"healthKitWorkoutId":"$workoutId"%'],
    );
    return result.isNotEmpty;
  }

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

  // ── NOTES ──────────────────────────────────────────────────────

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap());
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> softDeleteNote(String id) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'notes',
      {'is_deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> getNotesByDate(int dayEpoch) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'performed_on = ? AND is_deleted = 0',
      whereArgs: [dayEpoch],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<List<Record>> getRecordsByDateRange(int startMs, int endMs) async {
    final db = await database;
    final maps = await db.query(
      'records',
      where: 'performed_at >= ? AND performed_at < ? AND is_deleted = 0',
      whereArgs: [startMs, endMs],
      orderBy: 'performed_at ASC',
    );
    return maps.map(Record.fromMap).toList();
  }

  // ── MISC ───────────────────────────────────────────────────────

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
