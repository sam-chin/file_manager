import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/server_record.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'media_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE servers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            ip TEXT,
            username TEXT,
            password TEXT,
            shareName TEXT,
            type TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertServer(ServerRecord server) async {
    final db = await database;
    return await db.insert('servers', server.toMap());
  }

  Future<int> updateServer(ServerRecord server) async {
    final db = await database;
    return await db.update(
      'servers',
      server.toMap(),
      where: 'id = ?',
      whereArgs: [server.id],
    );
  }

  Future<int> deleteServer(int id) async {
    final db = await database;
    return await db.delete(
      'servers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ServerRecord>> getServers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('servers');
    return List.generate(maps.length, (i) => ServerRecord.fromMap(maps[i]));
  }
}
