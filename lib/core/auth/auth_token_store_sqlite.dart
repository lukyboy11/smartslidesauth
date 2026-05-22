import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'auth_token_store.dart';

class SqliteAuthTokenStore implements AuthTokenStore {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;

    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, 'auth_token.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            token TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<void> saveToken(String token) async {
    final db = _db;
    if (db == null) return;
    await db.delete('tokens');
    await db.insert('tokens', {'token': token});
  }

  @override
  Future<String?> getToken() async {
    final db = _db;
    if (db == null) return null;
    final result = await db.query('tokens', limit: 1);
    if (result.isNotEmpty) {
      return result.first['token'] as String;
    }
    return null;
  }

  @override
  Future<void> clearToken() async {
    final db = _db;
    if (db == null) return;
    await db.delete('tokens');
  }
}

final AuthTokenStore authTokenStoreInstance = SqliteAuthTokenStore();
