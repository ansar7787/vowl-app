import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Increments the authenticated user's [kidsCoins] balance by [amount].
class AwardKidsCoins extends UseCase<void, int> {
  final ShopRepository repository;

  AwardKidsCoins(this.repository);

  @override
  Future<Either<Failure, void>> call(int amount) =>
      repository.awardKidsCoins(amount);
}
