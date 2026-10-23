import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';

/// Domain repository interface for fetching Kids Zone curriculum quests.
abstract class KidsRepository {
  /// Retrieves kids quests for a given [gameType] and [level], returning a [Failure] or list of [KidsQuest].
  Future<Either<Failure, List<KidsQuest>>> getQuestsByLevel(
    String gameType,
    int level,
  );
}
