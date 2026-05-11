import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateUserRewards extends UseCase<void, UpdateUserRewardsParams> {
  final AuthRepository repository;

  UpdateUserRewards(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserRewardsParams params) async {
    return await repository.updateUserRewards(
      gameType: params.gameType,
      level: params.level,
      xpIncrease: params.xpIncrease,
      coinIncrease: params.coinIncrease,
      isDoubleReward: params.isDoubleReward,
    );
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
