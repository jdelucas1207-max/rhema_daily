import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/verse.dart';
import '../repositories/verse_repository.dart';

class GetAllVerses implements UseCase<List<Verse>, NoParams> {
  final VerseRepository repository;

  GetAllVerses(this.repository);

  @override
  Future<Either<Failure, List<Verse>>> call(NoParams params) {
    return repository.getAllVerses();
  }
}