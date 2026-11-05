import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/task.dart';

/// SQLite access layer.
///
/// Schema
///   tasks(id, title, description, due_date, is_completed, completed_at,
///         repeat_type, repeat_days, category, created_at)
///   subtasks(id, task_id -> tasks.id ON DELETE CASCADE, title, is_done)
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    String path;
    if (kIsWeb) {
      // Browser: SQLite compiled to WebAssembly, stored in IndexedDB.
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
      path = 'task_manager.db';
    } else {
      path = p.join(await getDatabasesPath(), 'task_manager.db');
    }
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            due_date INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_at INTEGER,
            repeat_type TEXT NOT NULL DEFAULT 'none',
            repeat_days TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT 'General',
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE subtasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_due ON tasks (due_date)');
        await db
            .execute('CREATE INDEX idx_subtasks_task ON subtasks (task_id)');
      },
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'due_date ASC');
    final subRows = await db.query('subtasks', orderBy: 'id ASC');
    final byTask = <int, List<SubTask>>{};
    for (final r in subRows) {
      byTask.putIfAbsent(r['task_id'] as int, () => []).add(SubTask.fromMap(r));
    }
    return rows
        .map((r) => Task.fromMap(r, byTask[r['id'] as int] ?? const []))
        .toList();
  }

  /// Inserts the task (and its subtasks) and returns the new id.
  Future<int> insertTask(Task t) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('tasks', t.toMap());
      for (final s in t.subtasks) {
        await txn.insert('subtasks', s.toMap(id));
      }
      return id;
    });
  }

  Future<void> updateTask(Task t) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [t.id]);
      for (final s in t.subtasks) {
        await txn.insert('subtasks', s.toMap(t.id!));
      }
    });
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('subtasks', where: 'task_id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
