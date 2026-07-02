import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';

/// Handles opening and managing the local SQLite database.
///
/// This phase only creates the schema foundation.
/// No verse content is inserted here.
class DatabaseService {
  Database? _database;

  Database get database {
    final db = _database;
    if (db == null) {
      throw StateError('DatabaseService has not been initialized.');
    }
    return db;
  }

  Future<void> init() async {
    if (_database != null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final databasePath = path.join(directory.path, DbConstants.databaseName);

    _database = await openDatabase(
      databasePath,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.versesTable} (
        ${DbConstants.columnId} TEXT PRIMARY KEY,
        ${DbConstants.columnBook} TEXT NOT NULL,
        ${DbConstants.columnChapter} INTEGER NOT NULL,
        ${DbConstants.columnVerse} INTEGER NOT NULL,
        ${DbConstants.columnTranslation} TEXT NOT NULL,
        ${DbConstants.columnVerseText} TEXT NOT NULL,
        ${DbConstants.columnAudioPath} TEXT,
        ${DbConstants.columnDurationInSeconds} INTEGER,
        ${DbConstants.columnCreatedAt} TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
