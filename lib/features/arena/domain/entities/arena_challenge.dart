import 'package:flutter/foundation.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

/// All mechanic types supported in the Arena Hybrid Pentathlon.
enum ArenaMechanicType {
  wordSnap,
  typeDuel,
  rapidJudge,
  sentenceBuild,
  spotError,
  mcq,
  speedSpell,
  voiceDuel, // v2.0 — future
}

/// Extension to convert mechanic type to/from string for JSON serialization.
extension ArenaMechanicTypeExt on ArenaMechanicType {
  String get key {
    switch (this) {
      case ArenaMechanicType.wordSnap:
        return 'word_snap';
      case ArenaMechanicType.typeDuel:
        return 'type_duel';
      case ArenaMechanicType.rapidJudge:
        return 'rapid_judge';
      case ArenaMechanicType.sentenceBuild:
        return 'sentence_build';
      case ArenaMechanicType.spotError:
        return 'spot_error';
      case ArenaMechanicType.mcq:
        return 'mcq';
      case ArenaMechanicType.speedSpell:
        return 'speed_spell';
      case ArenaMechanicType.voiceDuel:
        return 'voice_duel';
    }
  }

  /// Display name shown in round announce card and result dialog.
  String get displayName {
    switch (this) {
      case ArenaMechanicType.wordSnap:
        return 'Word Snap';
      case ArenaMechanicType.typeDuel:
        return 'Type Duel';
      case ArenaMechanicType.rapidJudge:
        return 'Rapid Fire Judge';
      case ArenaMechanicType.sentenceBuild:
        return 'Sentence Build';
      case ArenaMechanicType.spotError:
        return 'Spot the Error';
      case ArenaMechanicType.mcq:
        return 'MCQ Classic';
      case ArenaMechanicType.speedSpell:
        return 'Speed Spell';
      case ArenaMechanicType.voiceDuel:
        return 'Voice Duel';
    }
  }

  /// Emoji icon for round announce card and round strip.
  String get icon {
    switch (this) {
      case ArenaMechanicType.wordSnap:
        return '⚡';
      case ArenaMechanicType.typeDuel:
        return '📝';
      case ArenaMechanicType.rapidJudge:
        return '✅❌';
      case ArenaMechanicType.sentenceBuild:
        return '🧩';
      case ArenaMechanicType.spotError:
        return '🎯';
      case ArenaMechanicType.mcq:
        return '🎲';
      case ArenaMechanicType.speedSpell:
        return '🏆';
      case ArenaMechanicType.voiceDuel:
        return '🎙️';
    }
  }

  /// One-line instruction shown in round announce card.
  String get instruction {
    switch (this) {
      case ArenaMechanicType.wordSnap:
        return 'Unscramble the letters!';
      case ArenaMechanicType.typeDuel:
        return 'Type the word from memory!';
      case ArenaMechanicType.rapidJudge:
        return 'Correct or Wrong?';
      case ArenaMechanicType.sentenceBuild:
        return 'Arrange the words!';
      case ArenaMechanicType.spotError:
        return 'Tap the wrong word!';
      case ArenaMechanicType.mcq:
        return 'Choose the right answer!';
      case ArenaMechanicType.speedSpell:
        return 'Fill the missing letters!';
      case ArenaMechanicType.voiceDuel:
        return 'Pronounce the word!';
    }
  }

  /// Timer duration in seconds for this mechanic.
  int get timerSeconds {
    switch (this) {
      case ArenaMechanicType.rapidJudge:
        return 30;
      case ArenaMechanicType.typeDuel:
      case ArenaMechanicType.sentenceBuild:
        return 20;
      default:
        return 15;
    }
  }

  static ArenaMechanicType? tryFromKey(String key) {
    for (final type in ArenaMechanicType.values) {
      if (type.key == key) return type;
    }
    return null;
  }
}

/// A single sub-item inside a Rapid Fire Judge challenge.
@immutable
class RapidJudgeItem {
  final String sentence;
  final bool isCorrect;
  final String? correction;
  final String rule;

  const RapidJudgeItem({
    required this.sentence,
    required this.isCorrect,
    this.correction,
    required this.rule,
  });

  factory RapidJudgeItem.fromMap(Map<String, dynamic> map) {
    return RapidJudgeItem(
      sentence: map['sentence'] as String? ?? '',
      isCorrect: map['isCorrect'] as bool? ?? true,
      correction: map['correction'] as String?,
      rule: map['rule'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sentence': sentence,
      'isCorrect': isCorrect,
      if (correction != null) 'correction': correction,
      'rule': rule,
    };
  }
}

/// Polymorphic challenge model supporting all 7 Arena mechanic types.
///
/// Uses a flat class with nullable fields per mechanic type rather than
/// sealed class hierarchy — simpler for Firestore/JSON serialization.
@immutable
class ArenaChallenge {
  final ArenaMechanicType mechanic;
  final String id;
  final String prompt;
  final String correctAnswer;
  final String explanation;
  final String? difficulty;

  // MCQ fields (mechanic == mcq)
  final List<String>? options;
  final int? correctIndex;
  final String? discipline;

  // Word Snap fields (mechanic == wordSnap)
  final String? scrambledLetters;
  final String? hint;

  // Type Duel fields (mechanic == typeDuel)
  final List<String>? acceptedSpellings;
  final int? letterCount;

  // Rapid Judge fields (mechanic == rapidJudge)
  final List<RapidJudgeItem>? rapidItems;

  // Sentence Build fields (mechanic == sentenceBuild)
  final List<String>? shuffledWords;
  final int? wordCount;

  // Spot Error fields (mechanic == spotError)
  final List<String>? sentenceTokens;
  final int? errorTokenIndex;
  final String? errorToken;
  final String? correctedToken;

  // Speed Spell fields (mechanic == speedSpell)
  final String? displayMask;
  final List<String>? missingLetters;
  final List<int>? missingPositions;

  const ArenaChallenge({
    required this.mechanic,
    required this.id,
    required this.prompt,
    required this.correctAnswer,
    required this.explanation,
    this.difficulty,
    this.options,
    this.correctIndex,
    this.discipline,
    this.scrambledLetters,
    this.hint,
    this.acceptedSpellings,
    this.letterCount,
    this.rapidItems,
    this.shuffledWords,
    this.wordCount,
    this.sentenceTokens,
    this.errorTokenIndex,
    this.errorToken,
    this.correctedToken,
    this.displayMask,
    this.missingLetters,
    this.missingPositions,
  });

  /// Converts a legacy [ArenaQuestion] (MCQ-only) into an [ArenaChallenge].
  factory ArenaChallenge.fromLegacyQuestion(ArenaQuestion q) {
    return ArenaChallenge(
      mechanic: ArenaMechanicType.mcq,
      id: 'LEGACY_MCQ_${q.question.hashCode}',
      prompt: q.question,
      correctAnswer: q.options.length > q.correctIndex
          ? q.options[q.correctIndex]
          : '',
      explanation: q.explanation,
      difficulty: q.difficulty,
      options: q.options,
      correctIndex: q.correctIndex,
      discipline: q.discipline,
    );
  }

  /// Reverse converter for backward compat with code still using ArenaQuestion.
  ArenaQuestion toLegacyQuestion() {
    return ArenaQuestion(
      question: prompt,
      options: options ?? const [],
      correctIndex: correctIndex ?? 0,
      explanation: explanation,
      discipline: discipline,
      difficulty: difficulty,
    );
  }

  /// Forward-compatible deserialization. Returns null for unknown mechanic types
  /// (e.g., v2.0 voiceDuel parsed by old client) instead of crashing.
  static ArenaChallenge? tryFromMap(Map<String, dynamic> map) {
    try {
      final mechanicKey = map['mechanic'] as String?;
      if (mechanicKey == null) {
        // Legacy MCQ format: no 'mechanic' key → treat as MCQ
        return ArenaChallenge(
          mechanic: ArenaMechanicType.mcq,
          id: map['id'] as String? ??
              'LEGACY_${(map['question'] ?? '').hashCode}',
          prompt: map['question'] as String? ?? '',
          correctAnswer: _extractCorrectAnswer(map),
          explanation: map['explanation'] as String? ?? '',
          difficulty: map['difficulty'] as String?,
          options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
          correctIndex: (map['correctIndex'] as num?)?.toInt(),
          discipline: map['discipline'] as String?,
        );
      }

      final mechanic = ArenaMechanicTypeExt.tryFromKey(mechanicKey);
      if (mechanic == null) return null; // Unknown mechanic → skip gracefully

      return ArenaChallenge.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  factory ArenaChallenge.fromMap(Map<String, dynamic> map) {
    final mechanicKey = map['mechanic'] as String? ?? 'mcq';
    final mechanic =
        ArenaMechanicTypeExt.tryFromKey(mechanicKey) ?? ArenaMechanicType.mcq;

    return ArenaChallenge(
      mechanic: mechanic,
      id: map['id'] as String? ?? '',
      prompt: (map['prompt'] ?? map['question'] ?? map['definition'] ??
              map['instruction'] ?? '')
          .toString(),
      correctAnswer: (map['correctAnswer'] ??
              map['correctSentence'] ??
              map['errorToken'] ??
              '')
          .toString(),
      explanation: map['explanation'] as String? ?? '',
      difficulty: map['difficulty'] as String?,
      // MCQ
      options: (map['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctIndex: (map['correctIndex'] as num?)?.toInt(),
      discipline: map['discipline'] as String?,
      // Word Snap
      scrambledLetters: map['scrambledLetters'] as String?,
      hint: map['hint'] as String?,
      // Type Duel
      acceptedSpellings: (map['acceptedSpellings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      letterCount: (map['letterCount'] as num?)?.toInt(),
      // Rapid Judge
      rapidItems: (map['items'] as List<dynamic>?)
          ?.map(
            (e) => RapidJudgeItem.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      // Sentence Build
      shuffledWords: (map['shuffledWords'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      wordCount: (map['wordCount'] as num?)?.toInt(),
      // Spot Error
      sentenceTokens: (map['sentenceTokens'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      errorTokenIndex: (map['errorTokenIndex'] as num?)?.toInt(),
      errorToken: map['errorToken'] as String?,
      correctedToken: map['correctedToken'] as String?,
      // Speed Spell
      displayMask: map['displayMask'] as String?,
      missingLetters: (map['missingLetters'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      missingPositions: (map['missingPositions'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mechanic': mechanic.key,
      'id': id,
      'prompt': prompt,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      if (difficulty != null) 'difficulty': difficulty,
      // MCQ
      if (options != null) 'options': options,
      if (correctIndex != null) 'correctIndex': correctIndex,
      if (discipline != null) 'discipline': discipline,
      // Word Snap
      if (scrambledLetters != null) 'scrambledLetters': scrambledLetters,
      if (hint != null) 'hint': hint,
      // Type Duel
      if (acceptedSpellings != null) 'acceptedSpellings': acceptedSpellings,
      if (letterCount != null) 'letterCount': letterCount,
      // Rapid Judge
      if (rapidItems != null)
        'items': rapidItems!.map((e) => e.toMap()).toList(),
      // Sentence Build
      if (shuffledWords != null) 'shuffledWords': shuffledWords,
      if (wordCount != null) 'wordCount': wordCount,
      // Spot Error
      if (sentenceTokens != null) 'sentenceTokens': sentenceTokens,
      if (errorTokenIndex != null) 'errorTokenIndex': errorTokenIndex,
      if (errorToken != null) 'errorToken': errorToken,
      if (correctedToken != null) 'correctedToken': correctedToken,
      // Speed Spell
      if (displayMask != null) 'displayMask': displayMask,
      if (missingLetters != null) 'missingLetters': missingLetters,
      if (missingPositions != null) 'missingPositions': missingPositions,
    };
  }

  /// Extracts the correct answer text from a legacy MCQ map.
  static String _extractCorrectAnswer(Map<String, dynamic> map) {
    final options = (map['options'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final correctIndex = (map['correctIndex'] as num?)?.toInt();
    if (options != null &&
        correctIndex != null &&
        correctIndex < options.length) {
      return options[correctIndex];
    }
    return map['correctAnswer']?.toString() ?? '';
  }
}

/// Tracks the outcome of a single round for result dialog + match history.
@immutable
class ArenaRoundResult {
  final ArenaMechanicType mechanic;
  final bool isCorrect;
  final int myTimeMs;
  final int myPoints;
  final int? rapidCorrectItems;
  final int? rapidTotalItems;

  const ArenaRoundResult({
    required this.mechanic,
    required this.isCorrect,
    required this.myTimeMs,
    required this.myPoints,
    this.rapidCorrectItems,
    this.rapidTotalItems,
  });

  factory ArenaRoundResult.fromMap(Map<String, dynamic> map) {
    final mechanicKey = map['mechanic'] as String? ?? 'mcq';
    return ArenaRoundResult(
      mechanic:
          ArenaMechanicTypeExt.tryFromKey(mechanicKey) ?? ArenaMechanicType.mcq,
      isCorrect: map['correct'] as bool? ?? false,
      myTimeMs: (map['myTimeMs'] as num?)?.toInt() ?? 0,
      myPoints: (map['myPoints'] as num?)?.toInt() ?? 0,
      rapidCorrectItems: (map['rapidCorrectItems'] as num?)?.toInt(),
      rapidTotalItems: (map['rapidTotalItems'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mechanic': mechanic.key,
      'correct': isCorrect,
      'myTimeMs': myTimeMs,
      'myPoints': myPoints,
      if (rapidCorrectItems != null) 'rapidCorrectItems': rapidCorrectItems,
      if (rapidTotalItems != null) 'rapidTotalItems': rapidTotalItems,
    };
  }
}
