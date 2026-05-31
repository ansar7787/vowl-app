import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

class ClaimDailyChest extends UseCase<void, int> {
  final ShopRepository repository;

  ClaimDailyChest(this.repository);

  @override
  Future<Either<Failure, void>> call(int amount) async {
    return await repository.claimDailyChest(amount);
  }
}
