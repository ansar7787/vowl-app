import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/grammar_quest.dart';

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
