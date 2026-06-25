import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Claims the standard daily gift reward.
///
/// Returns [AuthFailure('Daily gift already claimed today')] when the gift was
/// already claimed within the current calendar day.
class ClaimDailyGift extends UseCase<void, NoParams> {
  final ShopRepository repository;

  ClaimDailyGift(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.claimDailyGift();
}
