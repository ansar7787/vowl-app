import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_learn_models.dart';

/// Exercise classification inside Practice Phase.
enum SynonymPracticeExerciseType { contrastSwap, synonymLadder }

/// Single context slot inside a Contrast Swap drill.
@immutable
class SynonymContrastSlot {
  final String contextTag;
  final String sentenceWithBlank;
  final String correctWord;
  final String feedback;

  const SynonymContrastSlot({
    required this.contextTag,
    required this.sentenceWithBlank,
    required this.correctWord,
    required this.feedback,
  });

  factory SynonymContrastSlot.fromJson(Map<String, dynamic> json) =>
      SynonymContrastSlot(
        contextTag: json['contextTag'] as String? ?? 'Context',
        sentenceWithBlank: json['sentenceWithBlank'] as String? ?? '',
        correctWord: json['correctWord'] as String? ?? '',
        feedback: json['feedback'] as String? ?? '',
      );
}

/// Single interactive exercise in Practice Phase ("Contrast Swap & Synonym Ladder").
@immutable
class SynonymPracticeExercise {
  final String parentId;
  final String cefr;
  final String baseWord;
  final String targetSynonym;
  final SynonymPracticeExerciseType type;
  final String prompt;
  final String hint;

  // Contrast Swap fields
  final List<String> pairWords;
  final List<SynonymContrastSlot> slots;

  // Synonym Ladder fields
  final String scaleAxis;
  final String lowLabel;
  final String highLabel;
  final List<String> shuffledWords;
  final List<String> orderedWords;
  final String explanation;
  final String spokenExample;

  const SynonymPracticeExercise({
    required this.parentId,
    required this.cefr,
    required this.baseWord,
    required this.targetSynonym,
    required this.type,
    required this.prompt,
    required this.hint,
    this.pairWords = const [],
    this.slots = const [],
    this.scaleAxis = '',
    this.lowLabel = '',
    this.highLabel = '',
    this.shuffledWords = const [],
    this.orderedWords = const [],
    this.explanation = '',
    this.spokenExample = '',
  });

  factory SynonymPracticeExercise.fromJson({
    required Map<String, dynamic> json,
    required String parentId,
    required String cefr,
    required String baseWord,
    required String targetSynonym,
  }) {
    final rawType = json['exerciseType'] as String? ?? 'contrastSwap';
    final type = rawType == 'synonymLadder'
        ? SynonymPracticeExerciseType.synonymLadder
        : SynonymPracticeExerciseType.contrastSwap;

    return SynonymPracticeExercise(
      parentId: parentId,
      cefr: cefr,
      baseWord: baseWord,
      targetSynonym: targetSynonym,
      type: type,
      prompt: json['prompt'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      pairWords:
          (json['pairWords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      slots:
          (json['slots'] as List<dynamic>?)
              ?.map(
                (e) => SynonymContrastSlot.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      scaleAxis: json['scaleAxis'] as String? ?? '',
      lowLabel: json['lowLabel'] as String? ?? 'Everyday',
      highLabel: json['highLabel'] as String? ?? 'Formal',
      shuffledWords:
          (json['shuffledWords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      orderedWords:
          (json['orderedWords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      explanation: json['explanation'] as String? ?? '',
      spokenExample: json['spokenExample'] as String? ?? '',
    );
  }
}

/// Pair entry containing exercises in a Practice batch JSON.
@immutable
class SynonymPracticeQuest {
  final String id;
  final int level;
  final String cefr;
  final int difficulty;
  final String word;
  final String targetSynonym;
  final List<SynonymPracticeExercise> exercises;

  const SynonymPracticeQuest({
    required this.id,
    required this.level,
    required this.cefr,
    required this.difficulty,
    required this.word,
    required this.targetSynonym,
    required this.exercises,
  });

  factory SynonymPracticeQuest.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final level = (json['level'] as num?)?.toInt() ?? 1;
    final cefr =
        json['cefr'] as String? ?? SynonymCefrHelper.cefrForLevel(level);
    final word = json['word'] as String? ?? '';
    final targetSynonym = json['targetSynonym'] as String? ?? '';
    return SynonymPracticeQuest(
      id: id,
      level: level,
      cefr: cefr,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      word: word,
      targetSynonym: targetSynonym,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map(
                (e) => SynonymPracticeExercise.fromJson(
                  json: Map<String, dynamic>.from(e as Map),
                  parentId: id,
                  cefr: cefr,
                  baseWord: word,
                  targetSynonym: targetSynonym,
                ),
              )
              .toList() ??
          const [],
    );
  }

  static List<SynonymPracticeExercise> fallbackExercises(int level) {
    final cefr = SynonymCefrHelper.cefrForLevel(level);
    return [
      SynonymPracticeExercise(
        parentId: 'FALLBACK_PRAC_$level',
        cefr: cefr,
        baseWord: 'Big',
        targetSynonym: 'Large',
        type: SynonymPracticeExerciseType.contrastSwap,
        prompt: "Place 'Big' and 'Large' into the context where each fits.",
        hint: "Use 'Big' for idioms and 'Large' for measurable quantities.",
        pairWords: const ['Big', 'Large'],
        slots: const [
          SynonymContrastSlot(
            contextTag: 'Team Celebration',
            sentenceWithBlank: 'Winning the cup was a ___ deal for our town!',
            correctWord: 'Big',
            feedback: "'Big deal' is an everyday idiom — never 'large deal'.",
          ),
          SynonymContrastSlot(
            contextTag: 'Shipping Report',
            sentenceWithBlank: 'The warehouse holds a ___ volume of cargo.',
            correctWord: 'Large',
            feedback: 'Measurable physical volume pairs naturally with large.',
          ),
        ],
      ),
      SynonymPracticeExercise(
        parentId: 'FALLBACK_PRAC_$level',
        cefr: cefr,
        baseWord: 'Big',
        targetSynonym: 'Large',
        type: SynonymPracticeExerciseType.synonymLadder,
        prompt: 'Order these related synonyms along the scale below.',
        hint:
            'Start with the simplest everyday word and end with the heaviest.',
        scaleAxis: 'Size & Impact',
        lowLabel: 'Everyday',
        highLabel: 'Extreme',
        shuffledWords: const ['Massive', 'Big', 'Huge'],
        orderedWords: const ['Big', 'Huge', 'Massive'],
        explanation:
            "'Big' is baseline size, 'Huge' adds strong surprise, and 'Massive' signals overwhelming scale.",
        spokenExample: 'A massive crowd gathered outside the main square.',
      ),
    ];
  }
}

/// Parsed Practice batch with interleaved drill ordering across a level's pairs.
@immutable
class SynonymPracticeBatch {
  final String gameType;
  final String phase;
  final String cefr;
  final int difficulty;
  final int batchIndex;
  final String levels;
  final List<SynonymPracticeQuest> quests;

  const SynonymPracticeBatch({
    required this.gameType,
    required this.phase,
    required this.cefr,
    required this.difficulty,
    required this.batchIndex,
    required this.levels,
    required this.quests,
  });

  factory SynonymPracticeBatch.fromJson(Map<String, dynamic> json) =>
      SynonymPracticeBatch(
        gameType: json['gameType'] as String? ?? 'synonymSearch',
        phase: json['phase'] as String? ?? 'practice',
        cefr: json['cefr'] as String? ?? 'A2',
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        batchIndex: (json['batchIndex'] as num?)?.toInt() ?? 1,
        levels: json['levels'] as String? ?? '1-10',
        quests:
            (json['quests'] as List<dynamic>?)
                ?.map(
                  (e) => SynonymPracticeQuest.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList() ??
            const [],
      );

  /// Interleaves exercises across pairs (Swap P1 -> Ladder P2 -> Swap P3 -> ...)
  /// so consecutive exercises never repeat the same base word.
  List<SynonymPracticeExercise> buildInterleavedExercisesForLevel(int level) {
    final matching = quests.where((q) => q.level == level).toList();
    final source = matching.isNotEmpty ? matching : quests.take(3).toList();
    if (source.isEmpty) {
      return SynonymPracticeQuest.fallbackExercises(level);
    }

    final swaps = <SynonymPracticeExercise>[];
    final ladders = <SynonymPracticeExercise>[];
    for (final q in source) {
      for (final ex in q.exercises) {
        if (ex.type == SynonymPracticeExerciseType.contrastSwap) {
          swaps.add(ex);
        } else {
          ladders.add(ex);
        }
      }
    }

    // Right-rotate ladders by 1 ([P_n-1, P_0, ...]) when 3+ pairs exist so
    // adjacent exercises (Swap(Pi) -> Ladder(P(i-1)) -> Swap(P(i+1))) never repeat the same word.
    final rotatedLadders = ladders.length >= 3
        ? [ladders.last, ...ladders.sublist(0, ladders.length - 1)]
        : (ladders.length == 2 ? [ladders[1], ladders[0]] : ladders);

    final result = <SynonymPracticeExercise>[];
    final maxLen = math.max(swaps.length, rotatedLadders.length);
    for (int i = 0; i < maxLen; i++) {
      if (i < swaps.length) result.add(swaps[i]);
      if (i < rotatedLadders.length) result.add(rotatedLadders[i]);
    }
    return result.isNotEmpty
        ? result
        : SynonymPracticeQuest.fallbackExercises(level);
  }
}
