import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';

abstract class GrammarRepository {
  Future<Either<Failure, List<GrammarQuest>>> getGrammarQuest({
    required GameSubtype gameType,
    required int level,
  });

  Future<void> preloadGrammarQuest({
    required GameSubtype gameType,
    required int level,
  });
}
