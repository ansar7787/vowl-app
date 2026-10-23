import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/domain/repositories/writing_repository.dart';

/// Parameters for executing the [GetWritingQuest] use case.
class GetWritingQuestParams extends Equatable {
  /// The target writing exercise subtype.
  final GameSubtype gameType;

  /// Progression level index.
  final int level;

  /// Creates a [GetWritingQuestParams] parameter set.
  const GetWritingQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case that retrieves writing quests from the [WritingRepository].
class GetWritingQuest
    implements UseCase<List<WritingQuest>, GetWritingQuestParams> {
  /// The backing writing repository.
  final WritingRepository repository;

  /// Creates a [GetWritingQuest] use case.
  GetWritingQuest(this.repository);

  @override
  Future<Either<Failure, List<WritingQuest>>> call(
    GetWritingQuestParams params,
  ) async {
    return await repository.getWritingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
