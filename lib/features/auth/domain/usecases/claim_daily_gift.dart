import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Claims the standard daily gift reward.
///
/// Returns [AuthFailure('daily-gift-already-claimed')] when the gift was
/// already claimed within the current calendar day. (Failure messages are
/// stable codes, not English sentences — see `FirebaseFailureHandlerMixin`'s
/// class doc for how the presentation layer should map them.)
class ClaimDailyGift extends UseCase<void, NoParams> {
  final ShopRepository repository;

  const ClaimDailyGift(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.claimDailyGift();
}
