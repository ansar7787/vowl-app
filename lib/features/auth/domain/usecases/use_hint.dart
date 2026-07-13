import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Consumes one hint from the authenticated user's [hintCount].
///
/// Runs inside a Firestore transaction to prevent the count from going
/// negative under concurrent requests. Returns
/// [AuthFailure('no-hints-available')] when [hintCount] is already zero.
class UseHint extends UseCase<void, NoParams> {
  final ShopRepository repository;

  const UseHint(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) => repository.useHint();
}
