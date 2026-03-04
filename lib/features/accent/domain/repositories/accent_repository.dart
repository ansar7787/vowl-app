import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/accent_quest.dart';

abstract class AccentRepository {
  Future<Either<Failure, List<AccentQuest>>> getAccentQuests({
    required GameSubtype gameType,
    required int level,
  });

  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  });

  Future<void> clearQuestCache();
}
