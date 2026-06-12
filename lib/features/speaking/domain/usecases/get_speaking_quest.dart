import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/domain/repositories/speaking_repository.dart';

class GetSpeakingQuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const GetSpeakingQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class GetSpeakingQuest implements UseCase<List<SpeakingQuest>, GetSpeakingQuestParams> {
  final SpeakingRepository repository;

  const GetSpeakingQuest(this.repository);

  @override
  Future<Either<Failure, List<SpeakingQuest>>> call(GetSpeakingQuestParams params) {
    return repository.getSpeakingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
