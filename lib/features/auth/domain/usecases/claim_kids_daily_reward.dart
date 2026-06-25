import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Claims the Kids Zone daily reward of [amount] kids-coins.
///
/// Returns [AuthFailure('Kids daily reward already claimed today')] when the
/// reward was already claimed within the current calendar day.
class ClaimKidsDailyReward extends UseCase<void, int> {
  final ShopRepository repository;

  ClaimKidsDailyReward(this.repository);

  @override
  Future<Either<Failure, void>> call(int amount) =>
      repository.claimKidsDailyReward(amount);
}
