import 'dart:math';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Helper coordinator to calculate dynamic sequence paths and custom quest mixes
/// for the discovery hub, ensuring perfect list limits and optimized memory footprints.
class DiscoveryHelper {
  // Private constructor to prevent instantiations
  const DiscoveryHelper._();

  static final Random _random = Random();

  /// Resolves dynamic quests based on specific hub sequence configurations.
  static List<GameQuest> getQuestsForSequence(
    String sequenceId,
    UserEntity user,
  ) {
    switch (sequenceId) {
      case 'daily_duo':
        return _generateDailyDuo(user);
      case 'speed_blitz':
        return _generateSpeedBlitz(user);
      case 'grammar_pro':
        return _generateGrammarPro(user);
      case 'smart_recommendation':
        return _generateSmartRecommendation(user);
      default:
        return _generateRandomQuest(user);
    }
  }

  static List<GameQuest> _generateSmartRecommendation(UserEntity user) {
    // 1. Find weakest category
    QuestType lowestType = QuestType.speaking;
    int lowestProgress = 9999;
    bool allZero = true;

    // 2. Find favorite category
    QuestType favoriteType = QuestType.vocabulary;
    int highestProgress = -1;

    for (final type in QuestType.values) {
      final cleared = user.getTotalCategoryLevelsCleared(type);
      if (cleared > 0) allZero = false;
      
      if (cleared < lowestProgress) {
        lowestProgress = cleared;
        lowestType = type;
      }
      
      if (cleared > highestProgress) {
        highestProgress = cleared;
        favoriteType = type;
      }
    }

    if (allZero) {
      final types = QuestType.values;
      lowestType = types[_random.nextInt(types.length)];
      favoriteType = types[_random.nextInt(types.length)];
    }

    final types = QuestType.values;
    final randomType = types[_random.nextInt(types.length)];

    // Curated mix: Weakest -> Favorite -> Random wildcard
    return [
      _getRandomGameForCategory(user, lowestType).copyWith(instruction: 'Let\'s strengthen your weak spots!'),
      _getRandomGameForCategory(user, favoriteType).copyWith(instruction: 'Play to your strengths.'),
      _getRandomGameForCategory(user, randomType).copyWith(instruction: 'A wildcard challenge!'),
    ];
  }

  static List<GameQuest> _generateDailyDuo(UserEntity user) {
    // Mixed vocal & listening/reading
    final speakingGame = _getRandomGameForCategory(user, QuestType.speaking);
    final isListening = _random.nextBool();
    final secondGame = _getRandomGameForCategory(user, isListening ? QuestType.listening : QuestType.reading);

    return [
      speakingGame.copyWith(instruction: 'Warm up your voice with this speaking drill.'),
      secondGame.copyWith(instruction: isListening ? 'Now tune your ears.' : 'Now focus on comprehension.'),
    ];
  }

  static List<GameQuest> _generateSpeedBlitz(UserEntity user) {
    // Fast, randomized challenges across categories
    return [
      _getRandomGameForCategory(user, QuestType.reading).copyWith(instruction: 'Read and react as fast as you can!'),
      _getRandomGameForCategory(user, QuestType.listening).copyWith(instruction: 'Listen carefully, answer quickly.'),
      _getRandomGameForCategory(user, QuestType.accent).copyWith(instruction: 'Rapid-fire pronunciation.'),
    ];
  }

  static List<GameQuest> _generateGrammarPro(UserEntity user) {
    // 3 distinct grammar drills
    final grammarGames = <GameQuest>{};
    int attempts = 0;
    while (grammarGames.length < 3 && attempts < 10) {
      grammarGames.add(_getRandomGameForCategory(user, QuestType.grammar));
      attempts++;
    }

    final list = grammarGames.toList();
    
    // Safety guard to always guarantee exactly 3 distinct entries
    int fallbackAttempts = 0;
    while (list.length < 3 && fallbackAttempts < 10) {
      list.add(_getRandomGameForCategory(user, QuestType.writing));
      fallbackAttempts++;
    }
    
    return list;
  }

  static List<GameQuest> _generateRandomQuest(UserEntity user) {
    final types = QuestType.values;
    final randomType = types[_random.nextInt(types.length)];
    return [_getRandomGameForCategory(user, randomType)];
  }

  static GameQuest _getRandomGameForCategory(UserEntity user, QuestType type) {
    // Filter out legacy subtypes that have no game data
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    if (subtypes.isEmpty) {
      // Fallback: pick any non-legacy subtype
      final fallback = GameSubtype.values.where((s) => !s.isLegacy).toList();
      final subtype = fallback[_random.nextInt(fallback.length)];
      return _getQuestForSubtype(user, subtype, 'Explore this quest!');
    }
    final subtype = subtypes[_random.nextInt(subtypes.length)];
    return _getQuestForSubtype(
      user,
      subtype,
      'Enhance your ${type.name} skills with this quest!',
    );
  }

  static GameQuest _getQuestForSubtype(
    UserEntity user,
    GameSubtype subtype,
    String instruction,
  ) {
    final currentLevel = user.unlockedLevels[subtype.name] ?? 1;
    return GameQuest(
      id: '${subtype.name}_$currentLevel',
      type: subtype.category,
      subtype: subtype,
      instruction: instruction,
      difficulty: currentLevel,
    );
  }
}

extension GameQuestX on GameQuest {
  GameQuest copyWith({
    String? id,
    QuestType? type,
    GameSubtype? subtype,
    String? instruction,
    int? difficulty,
  }) {
    return GameQuest(
      id: id ?? this.id,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      instruction: instruction ?? this.instruction,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
