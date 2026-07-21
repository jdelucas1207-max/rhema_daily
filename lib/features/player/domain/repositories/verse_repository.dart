import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/verse.dart';

abstract class VerseRepository {
  Future<Either<Failure, List<Verse>>> getAllVerses();

  Future<Either<Failure, Verse>> getVerseById(String id);
}