import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';

/// Domain repository contract defining writing curriculum access operations.
abstract class WritingRepository {
  /// Loads writing quests for the given [gameType] and progression [level].
  Future<Either<Failure, List<WritingQuest>>> getWritingQuest({
    required GameSubtype gameType,
    required int level,
  });
}
