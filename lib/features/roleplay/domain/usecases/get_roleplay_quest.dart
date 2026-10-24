import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/roleplay_quest.dart';
import '../repositories/roleplay_repository.dart';

/// Parameters for [GetRoleplayQuest] specifying subtype and curriculum level.
class GetRoleplayQuestParams extends Equatable {
  /// Roleplay game subtype requested.
  final GameSubtype gameType;

  /// Difficulty or curriculum level.
  final int level;

  /// Creates a [GetRoleplayQuestParams] instance.
  const GetRoleplayQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case fetching roleplay quests for a specified game type and level.
class GetRoleplayQuest
    implements UseCase<List<RoleplayQuest>, GetRoleplayQuestParams> {
  /// Roleplay repository dependency.
  final RoleplayRepository repository;

  /// Creates a [GetRoleplayQuest] use case instance.
  GetRoleplayQuest(this.repository);

  @override
  Future<Either<Failure, List<RoleplayQuest>>> call(
    GetRoleplayQuestParams params,
  ) {
    return repository.getRoleplayQuests(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
