import '../../../../core/domain/entities/game_quest.dart';
import '../repositories/roleplay_repository.dart';

/// Use case initiating asynchronous background preloading of upcoming roleplay quests.
class PreloadRoleplayQuests {
  /// Roleplay repository dependency.
  final RoleplayRepository repository;

  /// Creates a [PreloadRoleplayQuests] use case instance.
  PreloadRoleplayQuests(this.repository);

  Future<void> call({
    required GameSubtype gameType,
    required int currentLevel,
  }) {
    return repository.preloadNextBatch(
      gameType: gameType,
      currentLevel: currentLevel,
    );
  }
}
