import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Records a game-level completion and updates XP, coins, completed levels,
/// unlocked levels, daily XP history, and the recent-activity feed atomically
/// inside a single Firestore transaction.
///
/// ### Side effects
/// This use case is a pure data operation. Presentation-layer side effects
/// (e.g., in-app review prompts via [ReviewService]) must be invoked by the
/// caller on a [Right] result — the domain layer must not depend on
/// presentation services.
///
/// ```dart
/// final result = await updateUserRewards(params);
/// result.fold(
///   (failure) => handleFailure(failure),
///   (_) => reviewService.notifyQuestCompleted(),  // ← caller's responsibility
/// );
/// ```
class UpdateUserRewards extends UseCase<void, UpdateUserRewardsParams> {
  final GamificationRepository repository;

  const UpdateUserRewards(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserRewardsParams params) =>
      repository.updateUserRewards(
        gameType: params.gameType,
        level: params.level,
        xpIncrease: params.xpIncrease,
        coinIncrease: params.coinIncrease,
        isDoubleReward: params.isDoubleReward,
        starsEarned: params.starsEarned,
      );
}

/// Immutable value object carrying the reward parameters for [UpdateUserRewards].
@immutable
class UpdateUserRewardsParams extends Equatable {
  final String gameType;
  final int level;
  final int xpIncrease;
  final int coinIncrease;
  final bool isDoubleReward;
  final int? starsEarned;

  const UpdateUserRewardsParams({
    required this.gameType,
    required this.level,
    required this.xpIncrease,
    required this.coinIncrease,
    this.isDoubleReward = false,
    this.starsEarned,
  });

  @override
  List<Object?> get props => [
    gameType,
    level,
    xpIncrease,
    coinIncrease,
    isDoubleReward,
    starsEarned,
  ];
}
