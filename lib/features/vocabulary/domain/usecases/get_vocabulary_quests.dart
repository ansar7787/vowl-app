import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class GetVocabularyQuestsParams extends Equatable {
  /// The game sub-type string (e.g. `GameSubtype.flashcards.name`).
  final String gameType;

  /// 1-based level number.
  final int level;

  const GetVocabularyQuestsParams({
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [gameType, level];
}

class GetVocabularyQuests
    implements UseCase<List<VocabularyQuest>, GetVocabularyQuestsParams> {
  final VocabularyRepository repository;

  GetVocabularyQuests(this.repository);

  @override
  Future<Either<Failure, List<VocabularyQuest>>> call(
    GetVocabularyQuestsParams params,
  ) async {
    return repository.getVocabularyQuests(params.gameType, params.level);
  }
}
