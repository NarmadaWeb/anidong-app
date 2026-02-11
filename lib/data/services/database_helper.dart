// lib/data/services/database_helper.dart

import 'dart:convert';
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'anidong.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        type TEXT,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE history (
        original_url TEXT PRIMARY KEY,
        data TEXT,
        timestamp INTEGER
      )
    ''');
  }

  // Bookmarks
  Future<void> insertBookmark(Show show) async {
    final db = await database;
    await db.insert(
      'bookmarks',
      {
        'id': show.originalUrl ?? show.id.toString(),
        'type': show.type,
        'data': jsonEncode(show.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBookmark(Show show) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [show.originalUrl ?? show.id.toString()],
    );
  }

  Future<List<Show>> getBookmarks(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'type = ?',
      whereArgs: [type],
    );
    return List.generate(maps.length, (i) {
      return Show.fromJson(jsonDecode(maps[i]['data']));
    });
  }

  // History
  Future<void> insertHistory(Episode episode) async {
    final db = await database;
    await db.insert(
      'history',
      {
        'original_url': episode.originalUrl ?? episode.id.toString(),
        'data': jsonEncode(episode.toJson()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHistoryItem(String originalUrl) async {
    final db = await database;
    await db.delete(
      'history',
      where: 'original_url = ?',
      whereArgs: [originalUrl],
    );
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }

  Future<List<Episode>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'timestamp DESC',
      limit: 50,
    );
    return List.generate(maps.length, (i) {
      return Episode.fromJson(jsonDecode(maps[i]['data']));
    });
  }
}
