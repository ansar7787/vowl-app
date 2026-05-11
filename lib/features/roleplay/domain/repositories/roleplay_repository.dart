import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/roleplay_quest.dart';

abstract class RoleplayRepository {
  Future<Either<Failure, List<RoleplayQuest>>> getRoleplayQuests({
    required GameSubtype gameType,
    required int level,
  });

  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  });
}
