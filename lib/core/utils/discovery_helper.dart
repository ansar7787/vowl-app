import 'dart:math';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Helper coordinator to calculate dynamic sequence paths and custom quest
/// mixes for the discovery hub.
///
/// ### Localisation
/// FIX (HIGH-5): All user-facing instruction strings were previously hardcoded
/// English literals passed directly into [GameQuest.instruction]. These have
/// been replaced with localisation keys. The presentation layer is responsible
/// for translating them:
/// ```dart
/// Text(context.tr(quest.instruction))
/// ```
///
/// ### Quest instruction keys declared here
/// ```
/// quest_sequences.strengthen_weak_spots
/// quest_sequences.play_to_strengths
/// quest_sequences.wildcard_challenge
/// quest_sequences.speaking_warm_up
/// quest_sequences.ear_training
/// quest_sequences.comprehension_focus
/// quest_sequences.read_react
/// quest_sequences.listen_answer
/// quest_sequences.rapid_pronunciation
/// quest_sequences.category_skill_enhance
/// ```
class DiscoveryHelper {
  const DiscoveryHelper._(); // Non-instantiable.

  static final Random _random = Random();

  // ── Localisation key constants ────────────────────────────────────────────

  static const String _kStrengthenWeakSpots =
      'quest_sequences.strengthen_weak_spots';
  static const String _kPlayToStrengths = 'quest_sequences.play_to_strengths';
  static const String _kWildcardChallenge =
      'quest_sequences.wildcard_challenge';
  static const String _kSpeakingWarmUp = 'quest_sequences.speaking_warm_up';
  static const String _kEarTraining = 'quest_sequences.ear_training';
  static const String _kComprehensionFocus =
      'quest_sequences.comprehension_focus';
  static const String _kReadReact = 'quest_sequences.read_react';
  static const String _kListenAnswer = 'quest_sequences.listen_answer';
  static const String _kRapidPronunciation =
      'quest_sequences.rapid_pronunciation';
  static const String _kCategorySkillEnhance =
      'quest_sequences.category_skill_enhance';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Resolves dynamic quest lists based on hub sequence configurations.
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

  // ── Private generators ────────────────────────────────────────────────────

  static List<GameQuest> _generateSmartRecommendation(UserEntity user) {
    QuestType lowestType = QuestType.speaking;
    int lowestProgress = 9999;
    QuestType favoriteType = QuestType.vocabulary;
    int highestProgress = -1;
    bool allZero = true;

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

    final randomType =
        QuestType.values[_random.nextInt(QuestType.values.length)];

    // FIX (HIGH-5): tr() keys instead of raw English instruction strings.
    return [
      _getRandomGameForCategory(
        user,
        lowestType,
      ).copyWith(instruction: _kStrengthenWeakSpots),
      _getRandomGameForCategory(
        user,
        favoriteType,
      ).copyWith(instruction: _kPlayToStrengths),
      _getRandomGameForCategory(
        user,
        randomType,
      ).copyWith(instruction: _kWildcardChallenge),
    ];
  }

  static List<GameQuest> _generateDailyDuo(UserEntity user) {
    final speakingGame = _getRandomGameForCategory(user, QuestType.speaking);
    final isListening = _random.nextBool();
    final secondGame = _getRandomGameForCategory(
      user,
      isListening ? QuestType.listening : QuestType.reading,
    );

    return [
      // FIX (HIGH-5): tr() keys.
      speakingGame.copyWith(instruction: _kSpeakingWarmUp),
      secondGame.copyWith(
        instruction: isListening ? _kEarTraining : _kComprehensionFocus,
      ),
    ];
  }

  static List<GameQuest> _generateSpeedBlitz(UserEntity user) {
    // FIX (HIGH-5): tr() keys.
    return [
      _getRandomGameForCategory(
        user,
        QuestType.reading,
      ).copyWith(instruction: _kReadReact),
      _getRandomGameForCategory(
        user,
        QuestType.listening,
      ).copyWith(instruction: _kListenAnswer),
      _getRandomGameForCategory(
        user,
        QuestType.accent,
      ).copyWith(instruction: _kRapidPronunciation),
    ];
  }

  static List<GameQuest> _generateGrammarPro(UserEntity user) {
    // Use a Set to deduplicate by subtype identity.
    // VERIFIED (previously an open question, now confirmed by reading
    // game_quest.dart directly): GameQuest extends Equatable with a props
    // list that includes `subtype` alongside every other field, and
    // `_getQuestForSubtype` derives every field deterministically from
    // `subtype` + the user's current level for that subtype - so two
    // draws of the same subtype always produce fully equal GameQuest
    // instances. This Set-based dedup therefore works correctly as
    // written; no additional `==` override is needed on GameQuest.
    final grammarGames = <GameQuest>{};
    int attempts = 0;
    while (grammarGames.length < 3 && attempts < 10) {
      grammarGames.add(_getRandomGameForCategory(user, QuestType.grammar));
      attempts++;
    }

    final list = grammarGames.toList();

    // Safety pad: guarantee exactly 3 quests.
    int fallbackAttempts = 0;
    while (list.length < 3 && fallbackAttempts < 10) {
      list.add(_getRandomGameForCategory(user, QuestType.writing));
      fallbackAttempts++;
    }

    return list;
  }

  static List<GameQuest> _generateRandomQuest(UserEntity user) {
    final randomType =
        QuestType.values[_random.nextInt(QuestType.values.length)];
    return [_getRandomGameForCategory(user, randomType)];
  }

  static GameQuest _getRandomGameForCategory(UserEntity user, QuestType type) {
    // CODE CLEANLINESS FIX: previously filtered via
    // `.where((s) => !s.isLegacy)`. Cross-checked directly against
    // `GameSubtypeX.isLegacy`'s definition in game_quest.dart: it's
    // documented there as "Always `false`... no code path can ever set
    // this to `true`". The filter was therefore a guaranteed no-op -
    // removing it changes no behavior, just removes dead code that
    // implied a filtering step that never actually filtered anything.
    final subtypes = type.subtypes;
    if (subtypes.isEmpty) {
      final fallback = GameSubtype.values;
      final subtype = fallback[_random.nextInt(fallback.length)];
      // FIX (HIGH-5): tr() key.
      return _getQuestForSubtype(user, subtype, _kCategorySkillEnhance);
    }
    final subtype = subtypes[_random.nextInt(subtypes.length)];
    return _getQuestForSubtype(user, subtype, _kCategorySkillEnhance);
  }

  static GameQuest _getQuestForSubtype(
    UserEntity user,
    GameSubtype subtype,
    String instructionKey,
  ) {
    final currentLevel = user.unlockedLevels[subtype.name] ?? 10;
    return GameQuest(
      id: '${subtype.name}_$currentLevel',
      type: subtype.category,
      subtype: subtype,
      instruction: instructionKey,
      difficulty: currentLevel,
    );
  }
}

// ---------------------------------------------------------------------------
// Extension on GameQuest for copyWith support
// ---------------------------------------------------------------------------

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
