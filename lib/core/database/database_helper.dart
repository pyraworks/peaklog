import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/exercise.dart';
import '../models/record.dart';

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
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exercise_id INTEGER NOT NULL,
            value REAL NOT NULL,
            recorded_at INTEGER NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    return db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getExercises() async {
    final db = await database;
    final maps = await db.query('exercises', orderBy: 'order_index ASC');
    return maps.map(Exercise.fromMap).toList();
  }

  Future<void> deleteExercise(int id) async {
    final db = await database;
    await db.delete('records', where: 'exercise_id = ?', whereArgs: [id]);
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertRecord(Record record) async {
    final db = await database;
    return db.insert('records', record.toMap());
  }

  Future<List<Record>> getRecordsForExercise(int exerciseId) async {
    final db = await database;
    final maps = await db.query(
      'records',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'recorded_at DESC',
    );
    return maps.map(Record.fromMap).toList();
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
