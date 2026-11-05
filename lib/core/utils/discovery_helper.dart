import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Helper coordinator to calculate curriculum-synced sequence paths and
/// custom quest mixes for the discovery hub.
///
/// ### Determinism & Curriculum Alignment
/// Quests directly target the user's active game levels from the curriculum map
/// ([UserEntity.unlockedLevels]). When a user clears a level in a quest sequence,
/// their actual level in that game on the map is permanently updated and
/// all XP/Coins are credited natively through the game engine.
class DiscoveryHelper {
  const DiscoveryHelper._(); // Non-instantiable.

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

  static final Map<String, _DailyTrackCache> _trackCache = {};

  /// Clears in-memory daily track cache (useful for testing or date rollover).
  static void clearTrackCache() {
    _trackCache.clear();
  }

  /// Canonical identifier mapping to unify legacy and modern sequence alias keys.
  /// Canonical IDs are the modern production names: daily_workout, rapid_recall, sentence_lab, smart_focus.
  static String canonicalSequenceId(String sequenceId) {
    switch (sequenceId) {
      case 'daily_workout':
      case 'daily_duo':
        return 'daily_workout';
      case 'rapid_recall':
      case 'speed_blitz':
        return 'rapid_recall';
      case 'sentence_lab':
      case 'grammar_pro':
        return 'sentence_lab';
      case 'smart_focus':
      case 'smart_recommendation':
        return 'smart_focus';
      default:
        return sequenceId;
    }
  }

  /// Maps modern canonical IDs back to legacy development codenames for backward compatibility.
  static String legacySequenceId(String sequenceId) {
    switch (sequenceId) {
      case 'daily_workout':
      case 'daily_duo':
        return 'daily_duo';
      case 'rapid_recall':
      case 'speed_blitz':
        return 'speed_blitz';
      case 'sentence_lab':
      case 'grammar_pro':
        return 'grammar_pro';
      case 'smart_focus':
      case 'smart_recommendation':
        return 'smart_recommendation';
      default:
        return sequenceId;
    }
  }

  /// Sets or warms the daily track cache.
  static void setCachedTrack(
    String sequenceId,
    String userId,
    List<GameQuest> quests, {
    String? date,
  }) {
    final now = DateTime.now();
    final todayStr = date ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final canonical = canonicalSequenceId(sequenceId);
    final key = '${canonical}_$userId';
    _trackCache[key] = _DailyTrackCache(date: todayStr, quests: quests);
  }

  /// Resolves dynamic quest lists based on hub sequence configurations.
  /// Caches the generated track per sequence, user, and calendar day so
  /// in-session level completions do not prematurely bump uncompleted steps.
  static List<GameQuest> getQuestsForSequence(
    String sequenceId,
    UserEntity user,
  ) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final canonical = canonicalSequenceId(sequenceId);
    final key = '${canonical}_${user.id}';
    final cached = _trackCache[key];
    if (cached != null && cached.date == todayStr) {
      return cached.quests;
    }

    final quests = _resolveQuests(canonical, user);
    _trackCache[key] = _DailyTrackCache(date: todayStr, quests: quests);
    return quests;
  }

  static List<GameQuest> _resolveQuests(String sequenceId, UserEntity user) {
    switch (sequenceId) {
      case 'daily_duo':
      case 'daily_workout':
        return _generateDailyDuo(user);
      case 'speed_blitz':
      case 'rapid_recall':
        return _generateSpeedBlitz(user);
      case 'grammar_pro':
      case 'sentence_lab':
        return _generateGrammarPro(user);
      case 'smart_recommendation':
      case 'smart_focus':
        return _generateSmartRecommendation(user);
      default:
        return _generateRandomQuest(user);
    }
  }

  /// Primary curriculum subtype for each syllabus category.
  static GameSubtype primarySubtypeForCategory(QuestType type) {
    switch (type) {
      case QuestType.speaking:
        return GameSubtype.repeatSentence;
      case QuestType.listening:
        return GameSubtype.audioMultipleChoice;
      case QuestType.reading:
        return GameSubtype.readAndAnswer;
      case QuestType.writing:
        return GameSubtype.sentenceBuilder;
      case QuestType.grammar:
        return GameSubtype.tenseMastery;
      case QuestType.vocabulary:
        return GameSubtype.flashcards;
      case QuestType.accent:
        return GameSubtype.minimalPairs;
      case QuestType.roleplay:
        return GameSubtype.branchingDialogue;
      case QuestType.eliteMastery:
        return GameSubtype.storyBuilder;
    }
  }

  // ── Private generators ────────────────────────────────────────────────────

  static List<GameQuest> _generateSmartRecommendation(UserEntity user) {
    QuestType lowestType = QuestType.speaking;
    int lowestProgress = 999999;
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
      return [
        _getQuestForSubtype(
          user,
          GameSubtype.flashcards,
          _kPlayToStrengths,
        ),
        _getQuestForSubtype(
          user,
          GameSubtype.audioMultipleChoice,
          _kEarTraining,
        ),
        _getQuestForSubtype(
          user,
          GameSubtype.repeatSentence,
          _kSpeakingWarmUp,
        ),
      ];
    }

    if (favoriteType == lowestType) {
      favoriteType = QuestType.values.firstWhere(
        (t) => t != lowestType,
        orElse: () => QuestType.reading,
      );
    }

    final challengeTypes = [
      QuestType.speaking,
      QuestType.accent,
      QuestType.roleplay,
    ]..removeWhere((t) => t == lowestType || t == favoriteType);

    final challengeType = challengeTypes.isNotEmpty
        ? challengeTypes.first
        : QuestType.writing;

    return [
      _getQuestForSubtype(
        user,
        primarySubtypeForCategory(lowestType),
        _kStrengthenWeakSpots,
      ),
      _getQuestForSubtype(
        user,
        primarySubtypeForCategory(favoriteType),
        _kPlayToStrengths,
      ),
      _getQuestForSubtype(
        user,
        primarySubtypeForCategory(challengeType),
        _kWildcardChallenge,
      ),
    ];
  }

  static List<GameQuest> _generateDailyDuo(UserEntity user) {
    // Daily Workout:
    // Step 1: Speaking Warm-up (Repeat Sentence at user's current unlocked level)
    // Step 2: Comprehension Focus (Read & Answer at user's current unlocked level)
    return [
      _getQuestForSubtype(
        user,
        GameSubtype.repeatSentence,
        _kSpeakingWarmUp,
      ),
      _getQuestForSubtype(
        user,
        GameSubtype.readAndAnswer,
        _kComprehensionFocus,
      ),
    ];
  }

  static List<GameQuest> _generateSpeedBlitz(UserEntity user) {
    // Rapid Recall:
    // Step 1: Speed Reading (Reading Speed Check)
    // Step 2: Rapid Listening (Fast Speech Decoder)
    // Step 3: Pronunciation Clarity (Minimal Pairs)
    return [
      _getQuestForSubtype(
        user,
        GameSubtype.readingSpeedCheck,
        _kReadReact,
      ),
      _getQuestForSubtype(
        user,
        GameSubtype.fastSpeechDecoder,
        _kListenAnswer,
      ),
      _getQuestForSubtype(
        user,
        GameSubtype.minimalPairs,
        _kRapidPronunciation,
      ),
    ];
  }

  static List<GameQuest> _generateGrammarPro(UserEntity user) {
    // Sentence Lab:
    // Step 1: Word Reorder (Sentence Structure)
    // Step 2: Tense Mastery (Grammar Mechanics)
    // Step 3: Clause Connector (Complex Sentences)
    return [
      _getQuestForSubtype(
        user,
        GameSubtype.wordReorder,
        _kCategorySkillEnhance,
      ),
      _getQuestForSubtype(
        user,
        GameSubtype.tenseMastery,
        _kStrengthenWeakSpots,
      ),
      _getQuestForSubtype(
        user,
        GameSubtype.clauseConnector,
        _kPlayToStrengths,
      ),
    ];
  }

  static List<GameQuest> _generateRandomQuest(UserEntity user) {
    return [_getQuestForSubtype(user, GameSubtype.repeatSentence, _kCategorySkillEnhance)];
  }

  static GameQuest _getQuestForSubtype(
    UserEntity user,
    GameSubtype subtype,
    String instructionKey,
  ) {
    GameSubtype activeSubtype = subtype;
    int maxLevels = CurriculumManifest.getLevels(activeSubtype.name);
    int userLevel = user.unlockedLevels[activeSubtype.name] ?? 1;

    final isMastered = (maxLevels > 0) &&
        ((user.completedLevels[activeSubtype.name]?.contains(maxLevels) ?? false) ||
            ((user.completedLevels[activeSubtype.name]?.length ?? 0) >= maxLevels) ||
            (userLevel > maxLevels));

    // If the preferred game subtype has been completely mastered,
    // seamlessly rotate to the next uncompleted game in the same category!
    if (maxLevels > 0 && isMastered) {
      for (final alt in activeSubtype.category.subtypes) {
        final altMax = CurriculumManifest.getLevels(alt.name);
        final altMastered = (altMax > 0) &&
            ((user.completedLevels[alt.name]?.contains(altMax) ?? false) ||
                ((user.completedLevels[alt.name]?.length ?? 0) >= altMax) ||
                ((user.unlockedLevels[alt.name] ?? 1) > altMax));
        if (altMax > 0 && !altMastered) {
          activeSubtype = alt;
          maxLevels = altMax;
          userLevel = user.unlockedLevels[alt.name] ?? 1;
          break;
        }
      }
    }

    final currentLevel = userLevel.clamp(
      1,
      maxLevels > 0 ? maxLevels : 50,
    );
    return GameQuest(
      id: '${activeSubtype.name}_$currentLevel',
      type: activeSubtype.category,
      subtype: activeSubtype,
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
    int? xpReward,
    int? coinReward,
  }) {
    return GameQuest(
      id: id ?? this.id,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      instruction: instruction ?? this.instruction,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      interactionType: interactionType,
      livesAllowed: livesAllowed,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      correctAnswer: correctAnswer,
      correctAnswerCategory: correctAnswerCategory,
      question: question,
      sentence: sentence,
      targetWord: targetWord,
      hint: hint,
      explanation: explanation,
      textToSpeak: textToSpeak,
      visualConfig: visualConfig,
    );
  }
}

class _DailyTrackCache {
  final String date;
  final List<GameQuest> quests;

  const _DailyTrackCache({required this.date, required this.quests});
}
