import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../repositories/accent_repository.dart';
import '../entities/accent_quest.dart';

/// Use case for fetching a collection of accent quests for a given game subtype and level.
class GetAccentQuest {
  /// The underlying accent repository.
  final AccentRepository repository;

  /// Creates a [GetAccentQuest] use case with the given [repository].
  const GetAccentQuest(this.repository);

  /// Executes quest retrieval for the requested [params].
  Future<Either<Failure, List<AccentQuest>>> call(GetAccentQuestParams params) {
    return repository.getAccentQuests(
      gameType: params.gameType,
      level: params.level,
    );
  }
}

/// Parameters for [GetAccentQuest].
class GetAccentQuestParams {
  /// The target accent subgame subtype.
  final GameSubtype gameType;

  /// The level number to query.
  final int level;

  /// Creates a [GetAccentQuestParams] parameter object.
  const GetAccentQuestParams({required this.gameType, required this.level});
}
