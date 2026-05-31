import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

class ClaimKidsDailyReward extends UseCase<void, int> {
  final ShopRepository repository;

  ClaimKidsDailyReward(this.repository);

  @override
  Future<Either<Failure, void>> call(int amount) async {
    return await repository.claimKidsDailyReward(amount);
  }
}
