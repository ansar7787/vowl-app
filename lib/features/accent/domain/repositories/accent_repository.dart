import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/accent_quest.dart';

/// Domain contract for managing accent quest retrieval, prefetching, and cache invalidation.
abstract class AccentRepository {
  /// Retrieves a list of [AccentQuest]s for the given [gameType] and [level].
  Future<Either<Failure, List<AccentQuest>>> getAccentQuests({
    required GameSubtype gameType,
    required int level,
  });

  /// Preloads the next batch of quests in the background for [gameType] at [currentLevel].
  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  });

  /// Clears in-memory and disk caches for accent quests.
  Future<void> clearQuestCache();
}
