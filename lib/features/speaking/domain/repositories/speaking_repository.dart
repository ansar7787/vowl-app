import 'package:dartz/dartz.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

/// Domain repository contract for loading speaking quests.
abstract class SpeakingRepository {
  /// Fetches a list of speaking quests for [gameType] and difficulty [level].
  Future<Either<Failure, List<SpeakingQuest>>> getSpeakingQuest({
    required GameSubtype gameType,
    required int level,
  });
}
