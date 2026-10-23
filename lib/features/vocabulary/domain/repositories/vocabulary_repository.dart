import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Contract for fetching vocabulary quests and curriculum levels across vocabulary game modes.
abstract class VocabularyRepository {
  /// Fetches a list of [VocabularyQuest] items for the specified [gameType] and difficulty [level].
  Future<Either<Failure, List<VocabularyQuest>>> getVocabularyQuests(
    String gameType,
    int level,
  );
}
