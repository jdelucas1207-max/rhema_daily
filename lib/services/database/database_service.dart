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
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createVersesTable(db);
    await _createPlaylistSchema(db);
    await _seedVersesIfEmpty(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createPlaylistSchema(db);
    }
  }

  Future<void> _createVersesTable(Database db) async {
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
  }

  Future<void> _createPlaylistSchema(Database db) async {
    await _createPlaylistsTable(db);
    await _createPlaylistVersesTable(db);
    await _createPlaylistIndexes(db);
  }

  Future<void> _createPlaylistsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.playlistsTable} (
        ${DbConstants.columnId} TEXT PRIMARY KEY,
        ${DbConstants.columnName} TEXT NOT NULL,
        ${DbConstants.columnNormalizedName} TEXT NOT NULL UNIQUE,
        ${DbConstants.columnCreatedAt} TEXT NOT NULL,
        ${DbConstants.columnUpdatedAt} TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPlaylistVersesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.playlistVersesTable} (
        ${DbConstants.columnPlaylistId} TEXT NOT NULL,
        ${DbConstants.columnVerseId} TEXT NOT NULL,
        ${DbConstants.columnSortOrder} INTEGER NOT NULL,
        PRIMARY KEY (
          ${DbConstants.columnPlaylistId},
          ${DbConstants.columnVerseId}
        ),
        UNIQUE (
          ${DbConstants.columnPlaylistId},
          ${DbConstants.columnSortOrder}
        ),
        FOREIGN KEY (${DbConstants.columnPlaylistId})
          REFERENCES ${DbConstants.playlistsTable}(${DbConstants.columnId})
          ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.columnVerseId})
          REFERENCES ${DbConstants.versesTable}(${DbConstants.columnId})
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPlaylistIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS
        idx_playlist_verses_playlist_id
      ON ${DbConstants.playlistVersesTable} (
        ${DbConstants.columnPlaylistId}
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
        idx_playlist_verses_verse_id
      ON ${DbConstants.playlistVersesTable} (
        ${DbConstants.columnVerseId}
      )
    ''');
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