import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/verse.dart';
import '../repositories/verse_repository.dart';

class GetVerseById implements UseCase<Verse, String> {
  final VerseRepository repository;

  GetVerseById(this.repository);

  @override
  Future<Either<Failure, Verse>> call(String id) {
    return repository.getVerseById(id);
  }
}