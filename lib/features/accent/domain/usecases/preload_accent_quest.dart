import '../repositories/accent_repository.dart';
import '../../../../core/domain/entities/game_quest.dart';

class PreloadAccentQuest {
  final AccentRepository repository;

  PreloadAccentQuest(this.repository);

  Future<void> call(PreloadAccentQuestParams params) async {
    await repository.preloadNextBatch(
      gameType: params.gameType,
      currentLevel: params.level,
    );
  }
}

class PreloadAccentQuestParams {
  final GameSubtype gameType;
  final int level;

  const PreloadAccentQuestParams({required this.gameType, required this.level});
}
