import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../entities/elite_mastery_quest.dart';

/// Contract for querying domain-level elite mastery quest entities.
abstract class EliteMasteryRepository {
  /// Fetches a list of quests for [gameType] and [level], returning a [Failure] on error.
  Future<Either<Failure, List<EliteMasteryQuest>>> getEliteMasteryQuests({
    required GameSubtype gameType,
    required int level,
  });
}
