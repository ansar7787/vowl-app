import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/grammar_quest.dart';
import '../repositories/grammar_repository.dart';

/// Parameters for [GetGrammarQuest].
class GetGrammarQuestParams extends Equatable {
  /// The specific grammar game subtype.
  final GameSubtype gameType;

  /// The level index to query.
  final int level;

  /// Creates a [GetGrammarQuestParams] parameter instance.
  const GetGrammarQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case for retrieving a list of [GrammarQuest] entities for a level session.
class GetGrammarQuest
    implements UseCase<List<GrammarQuest>, GetGrammarQuestParams> {
  /// The underlying grammar repository.
  final GrammarRepository repository;

  /// Creates a [GetGrammarQuest] use case with the given [repository].
  const GetGrammarQuest(this.repository);

  @override
  Future<Either<Failure, List<GrammarQuest>>> call(
    GetGrammarQuestParams params,
  ) {
    return repository.getGrammarQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
