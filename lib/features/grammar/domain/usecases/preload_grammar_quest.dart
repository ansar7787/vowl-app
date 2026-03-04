import 'package:dartz/dartz.dart';
import 'package:voxai_quest/core/error/failures.dart';
import 'package:voxai_quest/core/usecases/usecase.dart';
import 'package:voxai_quest/features/grammar/domain/repositories/grammar_repository.dart';
import 'package:voxai_quest/features/speaking/domain/usecases/get_speaking_quest.dart';

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
