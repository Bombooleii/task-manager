import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            dueDate TEXT,
            isCompleted INTEGER DEFAULT 0,
            syncStatus TEXT DEFAULT 'pending_create',
            serverId TEXT
          )
        ''');
      },
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'syncStatus != ?',
      whereArgs: ['pending_delete'],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getPendingTasks() async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'syncStatus != ?',
      whereArgs: ['synced'],
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllAndInsert(List<Task> tasks) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks', where: 'syncStatus = ?', whereArgs: ['synced']);
      for (final task in tasks) {
        await txn.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
