// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/server_record.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'media_manager.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE servers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type INTEGER NOT NULL,
            name TEXT NOT NULL,
            host TEXT NOT NULL,
            port INTEGER DEFAULT 0,
            share TEXT,
            domain TEXT,
            username TEXT,
            encrypted_password TEXT,
            created_at INTEGER NOT NULL,
            last_connected INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE playback_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_url TEXT NOT NULL UNIQUE,
            position_ms INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Server CRUD ──────────────────────────────────────────

  static Future<List<ServerRecord>> getAllServers() async {
    final db = await _database;
    final rows = await db.query('servers', orderBy: 'created_at DESC');
    return rows.map(ServerRecord.fromMap).toList();
  }

  static Future<ServerRecord?> getServer(int id) async {
    final db = await _database;
    final rows = await db.query('servers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ServerRecord.fromMap(rows.first);
  }

  static Future<void> saveServer(ServerRecord server) async {
    final db = await _database;
    if (server.id == null) {
      final id = await db.insert('servers', server.toMap());
      server.id = id;
    } else {
      await db.update('servers', server.toMap(),
          where: 'id = ?', whereArgs: [server.id]);
    }
  }

  static Future<void> deleteServer(int id) async {
    final db = await _database;
    await db.delete('servers', where: 'id = ?', whereArgs: [id]);
  }

  // ── Playback History ─────────────────────────────────────

  static Future<int?> getPlaybackPosition(String fileUrl) async {
    final db = await _database;
    final rows = await db.query('playback_history',
        where: 'file_url = ?', whereArgs: [fileUrl]);
    if (rows.isEmpty) return null;
    return rows.first['position_ms'] as int;
  }

  static Future<void> savePlaybackPosition(
      String fileUrl, int positionMs) async {
    final db = await _database;
    await db.insert(
      'playback_history',
      {'file_url': fileUrl, 'position_ms': positionMs},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
