import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'settings_store.dart';

class SqliteSettingsStore implements SettingsStore {
  Database? _db;

  static const _dbName = 'smartslides.db';
  static const _dbVersion = 2;

  static const _table = 'app_settings';
  static const _colId = 'id';
  static const _colDarkMode = 'dark_mode';
  static const _colOnboardingSeen = 'onboarding_seen';

  @override
  Future<void> init() async {
    if (_db != null) return;

    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            $_colId INTEGER PRIMARY KEY,
            $_colDarkMode INTEGER NOT NULL,
            $_colOnboardingSeen INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.insert(
          _table,
          {_colId: 1, _colDarkMode: 1, _colOnboardingSeen: 0},
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN $_colOnboardingSeen INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );

    // Ensure row exists (in case DB existed but table empty).
    final existing = await _db!.query(
      _table,
      columns: [_colId],
      where: '$_colId = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (existing.isEmpty) {
      await _db!.insert(
        _table,
        {_colId: 1, _colDarkMode: 1, _colOnboardingSeen: 0},
      );
    }
  }

  @override
  Future<bool> getDarkMode() async {
    final db = _db;
    if (db == null) {
      throw StateError('SettingsStore not initialized. Call init() first.');
    }

    final rows = await db.query(
      _table,
      columns: [_colDarkMode],
      where: '$_colId = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final value = rows.first[_colDarkMode];
    return (value is int ? value : int.tryParse('$value') ?? 0) == 1;
  }

  @override
  Future<void> setDarkMode(bool value) async {
    final db = _db;
    if (db == null) {
      throw StateError('SettingsStore not initialized. Call init() first.');
    }

    await db.update(
      _table,
      {_colDarkMode: value ? 1 : 0},
      where: '$_colId = ?',
      whereArgs: [1],
    );
  }

  @override
  Future<bool> getOnboardingSeen() async {
    final db = _db;
    if (db == null) {
      throw StateError('SettingsStore not initialized. Call init() first.');
    }

    final rows = await db.query(
      _table,
      columns: [_colOnboardingSeen],
      where: '$_colId = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final value = rows.first[_colOnboardingSeen];
    return (value is int ? value : int.tryParse('$value') ?? 0) == 1;
  }

  @override
  Future<void> setOnboardingSeen(bool value) async {
    final db = _db;
    if (db == null) {
      throw StateError('SettingsStore not initialized. Call init() first.');
    }

    await db.update(
      _table,
      {_colOnboardingSeen: value ? 1 : 0},
      where: '$_colId = ?',
      whereArgs: [1],
    );
  }
}

final SettingsStore settingsStoreInstance = SqliteSettingsStore();

