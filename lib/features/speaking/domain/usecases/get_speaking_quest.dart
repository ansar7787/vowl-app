import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/domain/repositories/speaking_repository.dart';

/// Parameters for loading speaking quests.
class GetSpeakingQuestParams extends Equatable {
  /// Speaking subgame variant identifier.
  final GameSubtype gameType;

  /// Target progression difficulty level.
  final int level;

  /// Creates a [GetSpeakingQuestParams] container.
  const GetSpeakingQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case for retrieving speaking quests for a subgame mode and level.
class GetSpeakingQuest
    implements UseCase<List<SpeakingQuest>, GetSpeakingQuestParams> {
  /// Repository providing quest access.
  final SpeakingRepository repository;

  /// Creates a [GetSpeakingQuest] use case with [repository].
  const GetSpeakingQuest(this.repository);

  @override
  Future<Either<Failure, List<SpeakingQuest>>> call(
    GetSpeakingQuestParams params,
  ) {
    return repository.getSpeakingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
