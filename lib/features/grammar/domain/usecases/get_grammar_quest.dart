import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/grammar_quest.dart';
import '../repositories/grammar_repository.dart';

class GetGrammarQuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const GetGrammarQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class GetGrammarQuest implements UseCase<List<GrammarQuest>, GetGrammarQuestParams> {
  final GrammarRepository repository;

  const GetGrammarQuest(this.repository);

  @override
  Future<Either<Failure, List<GrammarQuest>>> call(GetGrammarQuestParams params) {
    return repository.getGrammarQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
