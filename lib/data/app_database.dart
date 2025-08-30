import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String dbName = 'speed_test.db';
  static const String tableResults = 'results';
  static const int dbVersion = 2;

  Database? _db;
  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('Database not initialized. Call AppDatabase.instance.init() first.');
    }
    return d;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);
    _db = await openDatabase(
      path,
      version: dbVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE IF NOT EXISTS $tableResults (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            connectionType TEXT NOT NULL,
            pingMs REAL NOT NULL,
            downloadMbps REAL NOT NULL,
            uploadMbps REAL NOT NULL
          );
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            CREATE TABLE IF NOT EXISTS $tableResults (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL,
              connectionType TEXT NOT NULL,
              pingMs REAL NOT NULL,
              downloadMbps REAL NOT NULL,
              uploadMbps REAL NOT NULL
            );
          ''');
        }
      },
      onOpen: (database) async {
        // Ensure table exists even if the database file pre-existed without it
        await database.execute('''
          CREATE TABLE IF NOT EXISTS $tableResults (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            connectionType TEXT NOT NULL,
            pingMs REAL NOT NULL,
            downloadMbps REAL NOT NULL,
            uploadMbps REAL NOT NULL
          );
        ''');
      },
    );
  }

  Future<void> clearAll() async {
    await db.delete(tableResults);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
