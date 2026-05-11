import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/domain/repositories/speaking_repository.dart';

class GetSpeakingQuest implements UseCase<List<SpeakingQuest>, QuestParams> {
  final SpeakingRepository repository;

  GetSpeakingQuest(this.repository);

  @override
  Future<Either<Failure, List<SpeakingQuest>>> call(QuestParams params) async {
    return await repository.getSpeakingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}

class QuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const QuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}
