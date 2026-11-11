import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Parameters for [PurchaseLevelUnlock].
class PurchaseLevelUnlockParams extends Equatable {
  final String gameType;
  final int cost;

  const PurchaseLevelUnlockParams({
    required this.gameType,
    required this.cost,
  });

  @override
  List<Object?> get props => [gameType, cost];
}

/// Deducts [PurchaseLevelUnlockParams.cost] Golden Keys and increments the
/// unlocked level for [PurchaseLevelUnlockParams.gameType] by 3. Used for
/// Toll Gate monetization.
///
/// Returns [AuthFailure('insufficient-golden-keys')] when the balance is
/// insufficient. Runs atomically inside a Firestore transaction.
class PurchaseLevelUnlock extends UseCase<void, PurchaseLevelUnlockParams> {
  final GamificationRepository repository;

  const PurchaseLevelUnlock(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseLevelUnlockParams params) async {
    return await repository.purchaseLevelUnlock(
      gameType: params.gameType,
      cost: params.cost,
    );
  }
}
