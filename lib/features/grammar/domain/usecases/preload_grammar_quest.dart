import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/grammar_repository.dart';

class PreloadGrammarQuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const PreloadGrammarQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class PreloadGrammarQuest implements UseCase<void, PreloadGrammarQuestParams> {
  final GrammarRepository repository;

  const PreloadGrammarQuest(this.repository);

  @override
  Future<Either<Failure, void>> call(PreloadGrammarQuestParams params) async {
    await repository.preloadGrammarQuest(
      gameType: params.gameType,
      level: params.level,
    );
    return const Right(null);
  }
}
