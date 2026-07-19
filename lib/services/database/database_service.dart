import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../../features/player/data/datasources/verse_seed_data.dart';

/// Handles opening, creating, and managing the local SQLite database.
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
    final databasePath = path.join(
      directory.path,
      DbConstants.databaseName,
    );

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
        ${DbConstants.columnCreatedAt} TEXT NOT NULL,
        UNIQUE (
          ${DbConstants.columnBook},
          ${DbConstants.columnChapter},
          ${DbConstants.columnVerse},
          ${DbConstants.columnTranslation}
        )
      )
    ''');

    await _seedVersesIfEmpty(db);
  }

  Future<void> _seedVersesIfEmpty(Database db) async {
    final countResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS verse_count
      FROM ${DbConstants.versesTable}
      ''',
    );

    final verseCount = Sqflite.firstIntValue(countResult) ?? 0;

    if (verseCount > 0) {
      return;
    }

    final batch = db.batch();

    for (final verse in VerseSeedData.verses) {
      batch.insert(
        DbConstants.versesTable,
        verse.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}