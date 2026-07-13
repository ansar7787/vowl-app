import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Claims the daily chest reward of [amount] coins.
///
/// Returns [AuthFailure('daily-chest-already-claimed')] if the chest was
/// already claimed within the current calendar day. (Failure messages are
/// stable codes, not English sentences, so the presentation layer can
/// localize them — see `FirebaseFailureHandlerMixin`'s class doc.)
class ClaimDailyChest extends UseCase<void, int> {
  final ShopRepository repository;

  const ClaimDailyChest(this.repository);

  @override
  Future<Either<Failure, void>> call(int amount) =>
      repository.claimDailyChest(amount);
}
