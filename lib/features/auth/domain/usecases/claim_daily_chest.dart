import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Claims the daily chest reward of [amount] coins.
///
/// Returns [AuthFailure('Daily chest already claimed today')] if the chest
/// was already claimed within the current calendar day.
class ClaimDailyChest extends UseCase<void, int> {
  final ShopRepository repository;

  ClaimDailyChest(this.repository);

  @override
  Future<Either<Failure, void>> call(int amount) =>
      repository.claimDailyChest(amount);
}
