import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Shared use case contract for Clean Architecture.
///
/// [Type] is the result type.
/// [Params] is the input type.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use this when a use case takes no input.
class NoParams {
  const NoParams();
}
