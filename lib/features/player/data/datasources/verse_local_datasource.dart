import '../../../../core/constants/db_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/database/database_service.dart';
import '../models/verse_model.dart';

abstract class VerseLocalDataSource {
  Future<List<VerseModel>> getAllVerses();

  Future<VerseModel> getVerseById(String id);
}

class VerseLocalDataSourceImpl implements VerseLocalDataSource {
  final DatabaseService databaseService;

  VerseLocalDataSourceImpl({
    required this.databaseService,
  });

  @override
  Future<List<VerseModel>> getAllVerses() async {
    try {
      final results = await databaseService.database.query(
        DbConstants.versesTable,
        orderBy:
            '${DbConstants.columnBook}, ${DbConstants.columnChapter}, ${DbConstants.columnVerse}',
      );

      return results.map(VerseModel.fromMap).toList();
    } catch (error) {
      throw DatabaseException(
        'Failed to load verses from the local database: $error',
      );
    }
  }

  @override
  Future<VerseModel> getVerseById(String id) async {
    try {
      final results = await databaseService.database.query(
        DbConstants.versesTable,
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) {
        throw const VerseNotFoundException('Verse not found.');
      }

      return VerseModel.fromMap(results.first);
    } on VerseNotFoundException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to load verse from the local database: $error',
      );
    }
  }
}
