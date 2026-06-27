import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

class PurchaseLevelUnlockParams extends Equatable {
  final String gameType;
  final int cost;
  final bool isKidsMode;

  const PurchaseLevelUnlockParams({
    required this.gameType,
    required this.cost,
    this.isKidsMode = false,
  });

  @override
  List<Object?> get props => [gameType, cost, isKidsMode];
}

class PurchaseLevelUnlock implements UseCase<void, PurchaseLevelUnlockParams> {
  final GamificationRepository repository;

  PurchaseLevelUnlock(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseLevelUnlockParams params) async {
    return await repository.purchaseLevelUnlock(
      gameType: params.gameType,
      cost: params.cost,
      isKidsMode: params.isKidsMode,
    );
  }
}
