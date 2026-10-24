import '../repositories/accent_repository.dart';
import '../../../../core/domain/entities/game_quest.dart';

/// Use case for proactively preloading the upcoming batch of accent quests.
class PreloadAccentQuest {
  /// The underlying accent repository.
  final AccentRepository repository;

  /// Creates a [PreloadAccentQuest] use case with the given [repository].
  const PreloadAccentQuest(this.repository);

  /// Triggers background prefetching for the specified [params].
  Future<void> call(PreloadAccentQuestParams params) {
    return repository.preloadNextBatch(
      gameType: params.gameType,
      currentLevel: params.level,
    );
  }
}

/// Parameters for [PreloadAccentQuest].
class PreloadAccentQuestParams {
  /// The target accent subgame subtype.
  final GameSubtype gameType;

  /// The player's active level number.
  final int level;

  /// Creates a [PreloadAccentQuestParams] parameter object.
  const PreloadAccentQuestParams({required this.gameType, required this.level});
}
