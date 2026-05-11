import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/roleplay_quest.dart';
import '../repositories/roleplay_repository.dart';

class GetRoleplayQuest {
  final RoleplayRepository repository;

  GetRoleplayQuest(this.repository);

  Future<Either<Failure, List<RoleplayQuest>>> call({
    required GameSubtype gameType,
    required int level,
  }) async {
    return await repository.getRoleplayQuests(gameType: gameType, level: level);
  }
}
