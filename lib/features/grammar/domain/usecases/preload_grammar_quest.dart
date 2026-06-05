import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/speaking/domain/usecases/get_speaking_quest.dart';
import '../repositories/grammar_repository.dart';

class PreloadGrammarQuest implements UseCase<void, QuestParams> {
  final GrammarRepository repository;

  const PreloadGrammarQuest(this.repository);

  @override
  Future<Either<Failure, void>> call(QuestParams params) async {
    await repository.preloadGrammarQuest(
      gameType: params.gameType,
      level: params.level,
    );
    return const Right(null);
  }
}
