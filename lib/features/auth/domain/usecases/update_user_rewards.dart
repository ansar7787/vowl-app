import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/review_service.dart';

class UpdateUserRewards extends UseCase<void, UpdateUserRewardsParams> {
  final GamificationRepository repository;

  UpdateUserRewards(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserRewardsParams params) async {
    final result = await repository.updateUserRewards(
      gameType: params.gameType,
      level: params.level,
      xpIncrease: params.xpIncrease,
      coinIncrease: params.coinIncrease,
      isDoubleReward: params.isDoubleReward,
    );

    // Organically notify ReviewService upon successful level completions
    result.fold(
      (failure) => null,
      (_) {
        try {
          di.sl<ReviewService>().notifyQuestCompleted();
        } catch (_) {}
      },
    );

    return result;
  }
}

class UpdateUserRewardsParams extends Equatable {
  final String gameType;
  final int level;
  final int xpIncrease;
  final int coinIncrease;
  final bool isDoubleReward;

  const UpdateUserRewardsParams({
    required this.gameType,
    required this.level,
    required this.xpIncrease,
    required this.coinIncrease,
    this.isDoubleReward = false,
  });

  @override
  List<Object?> get props => [gameType, level, xpIncrease, coinIncrease, isDoubleReward];
}
