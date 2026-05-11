import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/domain/repositories/grammar_repository.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart'; // For QuestParams

class GetGrammarQuest implements UseCase<List<GrammarQuest>, QuestParams> {
  final GrammarRepository repository;

  GetGrammarQuest(this.repository);

  @override
  Future<Either<Failure, List<GrammarQuest>>> call(QuestParams params) async {
    return await repository.getGrammarQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
