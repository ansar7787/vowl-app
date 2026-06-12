import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/roleplay_quest.dart';
import '../repositories/roleplay_repository.dart';

class GetRoleplayQuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const GetRoleplayQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class GetRoleplayQuest implements UseCase<List<RoleplayQuest>, GetRoleplayQuestParams> {
  final RoleplayRepository repository;

  GetRoleplayQuest(this.repository);

  @override
  Future<Either<Failure, List<RoleplayQuest>>> call(GetRoleplayQuestParams params) {
    return repository.getRoleplayQuests(gameType: params.gameType, level: params.level);
  }
}
