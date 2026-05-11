import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/grammar/domain/repositories/grammar_repository.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';

class PreloadGrammarQuest implements UseCase<void, QuestParams> {
  final GrammarRepository repository;

  PreloadGrammarQuest(this.repository);

  @override
  Future<Either<Failure, void>> call(QuestParams params) async {
    await repository.preloadGrammarQuest(
      gameType: params.gameType,
      level: params.level,
    );
    return const Right(null);
  }
}
