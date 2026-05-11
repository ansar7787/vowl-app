import '../../../../core/domain/entities/game_quest.dart';
import '../repositories/roleplay_repository.dart';

class PreloadRoleplayQuests {
  final RoleplayRepository repository;

  PreloadRoleplayQuests(this.repository);

  Future<void> call({
    required GameSubtype gameType,
    required int currentLevel,
  }) async {
    await repository.preloadNextBatch(
      gameType: gameType,
      currentLevel: currentLevel,
    );
  }
}
