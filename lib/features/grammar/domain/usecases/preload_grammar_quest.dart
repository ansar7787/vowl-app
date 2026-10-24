import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/grammar_repository.dart';

/// Parameters for [PreloadGrammarQuest].
class PreloadGrammarQuestParams extends Equatable {
  /// The target grammar game subtype.
  final GameSubtype gameType;

  /// The level index to preload.
  final int level;

  /// Creates a [PreloadGrammarQuestParams] parameter instance.
  const PreloadGrammarQuestParams({
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case for proactively preloading grammar quests into local cache.
class PreloadGrammarQuest implements UseCase<void, PreloadGrammarQuestParams> {
  /// The underlying grammar repository.
  final GrammarRepository repository;

  /// Creates a [PreloadGrammarQuest] use case with the given [repository].
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
