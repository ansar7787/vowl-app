import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/speaking/domain/usecases/get_speaking_quest.dart'; // For QuestParams
import '../entities/grammar_quest.dart';
import '../repositories/grammar_repository.dart';

class GetGrammarQuest implements UseCase<List<GrammarQuest>, QuestParams> {
  final GrammarRepository repository;

  const GetGrammarQuest(this.repository);

  @override
  Future<Either<Failure, List<GrammarQuest>>> call(QuestParams params) {
    return repository.getGrammarQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
