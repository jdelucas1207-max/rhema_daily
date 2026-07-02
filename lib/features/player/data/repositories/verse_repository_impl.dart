import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/verse.dart';
import '../../domain/repositories/verse_repository.dart';
import '../datasources/verse_local_datasource.dart';

class VerseRepositoryImpl implements VerseRepository {
  final VerseLocalDataSource localDataSource;

  VerseRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Verse>>> getAllVerses() async {
    try {
      final verses = await localDataSource.getAllVerses();
      return Right(verses);
    } on DatabaseException catch (error) {
      return Left(DatabaseFailure(error.message));
    }
  }

  @override
  Future<Either<Failure, Verse>> getVerseById(String id) async {
    try {
      final verse = await localDataSource.getVerseById(id);
      return Right(verse);
    } on VerseNotFoundException catch (error) {
      return Left(VerseNotFoundFailure(error.message));
    } on DatabaseException catch (error) {
      return Left(DatabaseFailure(error.message));
    }
  }
}
