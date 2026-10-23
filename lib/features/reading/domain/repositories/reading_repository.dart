import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/reading_quest.dart';

/// Contract defining data operations for reading quests.
abstract class ReadingRepository {
  /// Retrieves reading quests matching the specified [gameType] and difficulty [level].
  Future<Either<Failure, List<ReadingQuest>>> getReadingQuest({
    required GameSubtype gameType,
    required int level,
  });
}
