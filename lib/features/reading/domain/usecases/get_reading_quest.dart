import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reading_quest.dart';
import '../repositories/reading_repository.dart';

/// Parameters for [GetReadingQuest] specifying subtype and curriculum level.
class GetReadingQuestParams extends Equatable {
  /// The reading game subtype requested.
  final GameSubtype gameType;

  /// The difficulty or curriculum level of the quest.
  final int level;

  /// Creates a [GetReadingQuestParams] instance.
  const GetReadingQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case fetching reading quests for a specified game type and level.
class GetReadingQuest
    implements UseCase<List<ReadingQuest>, GetReadingQuestParams> {
  /// Reading repository dependency.
  final ReadingRepository repository;

  /// Creates a [GetReadingQuest] use case instance.
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
