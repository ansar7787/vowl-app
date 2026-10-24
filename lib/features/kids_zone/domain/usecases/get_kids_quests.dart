import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/domain/repositories/kids_repository.dart';

/// Use case for retrieving Kids Zone quests for a specific game type and level.
class GetKidsQuests {
  /// The underlying repository for quest retrieval.
  final KidsRepository repository;

  /// Creates a [GetKidsQuests] use case with the provided [repository].
  const GetKidsQuests(this.repository);

  /// Executes the quest retrieval for [gameType] at [level].
  Future<Either<Failure, List<KidsQuest>>> call(String gameType, int level) {
    return repository.getQuestsByLevel(gameType, level);
  }
}
