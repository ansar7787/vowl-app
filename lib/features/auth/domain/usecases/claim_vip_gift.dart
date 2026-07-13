import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

/// Claims the VIP daily gift (100 coins) for premium subscribers.
///
/// Returns [AuthFailure('user-not-premium')] for non-premium users and
/// [AuthFailure('vip-gift-already-claimed')] when already claimed today.
class ClaimVipGift extends UseCase<void, NoParams> {
  final UserRepository repository;

  const ClaimVipGift(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.claimVipGift();
}
