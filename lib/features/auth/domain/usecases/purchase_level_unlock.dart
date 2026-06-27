import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

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

class PurchaseLevelUnlock implements UseCase<void, PurchaseLevelUnlockParams> {
  final GamificationRepository repository;

  PurchaseLevelUnlock(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseLevelUnlockParams params) async {
    return await repository.purchaseLevelUnlock(
      gameType: params.gameType,
      cost: params.cost,
    );
  }
}
