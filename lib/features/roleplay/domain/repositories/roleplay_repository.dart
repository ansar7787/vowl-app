import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/roleplay_quest.dart';

/// Contract defining data operations for roleplay simulations.
abstract class RoleplayRepository {
  /// Retrieves roleplay quests for [gameType] and difficulty [level].
  Future<Either<Failure, List<RoleplayQuest>>> getRoleplayQuests({
    required GameSubtype gameType,
    required int level,
  });

  /// Preloads upcoming levels in the background.
  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  });
}
