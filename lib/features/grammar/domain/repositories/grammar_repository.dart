import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/grammar_quest.dart';

/// Domain contract defining grammar quest querying and preloading.
abstract class GrammarRepository {
  /// Retrieves a list of [GrammarQuest]s for the given [gameType] and [level].
  Future<Either<Failure, List<GrammarQuest>>> getGrammarQuest({
    required GameSubtype gameType,
    required int level,
  });

  /// Preloads grammar quests in the background for [gameType] at [level].
  Future<void> preloadGrammarQuest({
    required GameSubtype gameType,
    required int level,
  });
}
