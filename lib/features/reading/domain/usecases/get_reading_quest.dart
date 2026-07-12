import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reading_quest.dart';
import '../repositories/reading_repository.dart';

class GetReadingQuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const GetReadingQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class GetReadingQuest
    implements UseCase<List<ReadingQuest>, GetReadingQuestParams> {
  final ReadingRepository repository;

  const GetReadingQuest(this.repository);

  @override
  Future<Either<Failure, List<ReadingQuest>>> call(
    GetReadingQuestParams params,
  ) {
    return repository.getReadingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
