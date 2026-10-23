import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Input parameters for retrieving vocabulary quests by game mode and level.
class GetVocabularyQuestsParams extends Equatable {
  /// The game sub-type string (e.g. `GameSubtype.flashcards.name`).
  final String gameType;

  /// 1-based level number.
  final int level;

  /// Creates a [GetVocabularyQuestsParams] descriptor.
  const GetVocabularyQuestsParams({
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case that retrieves vocabulary quests for a specified game type and curriculum level.
class GetVocabularyQuests
    implements UseCase<List<VocabularyQuest>, GetVocabularyQuestsParams> {
  /// The repository instance managing vocabulary quest persistence.
  final VocabularyRepository repository;

  /// Creates a [GetVocabularyQuests] use case with the provided [repository].
  GetVocabularyQuests(this.repository);

  @override
  Future<Either<Failure, List<VocabularyQuest>>> call(
    GetVocabularyQuestsParams params,
  ) async {
    return repository.getVocabularyQuests(params.gameType, params.level);
  }
}
