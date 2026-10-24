import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/listening_quest.dart';

/// Domain repository contract for loading listening quests.
abstract class ListeningRepository {
  /// Fetches listening quests for [gameType] and difficulty [level].
  Future<Either<Failure, List<ListeningQuest>>> getListeningQuests({
    required GameSubtype gameType,
    required int level,
  });
}
