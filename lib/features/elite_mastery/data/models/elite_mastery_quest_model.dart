import '../../domain/entities/elite_mastery_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class EliteMasteryQuestModel extends EliteMasteryQuest {
  const EliteMasteryQuestModel({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.textToSpeak,
    super.visualConfig,
    super.question,
    super.sentences,
    super.correctOrder,
    super.idiom,
    super.word,
    super.speedMultiplier,
    super.audioUrl,
    super.text,
    super.explanation,
    super.shadowingFocus,
    super.usageContext,
    super.spellingRule,
    super.sequenceLogic,
    super.plotStructure,
    super.idiomOrigin,
    super.visualMetaphor,
    super.difficultyTier,
    super.targetAccent,
  });

  factory EliteMasteryQuestModel.fromJson(Map<String, dynamic> json) {
    final subtype = GameSubtype.fromString(
      json['subtype'] as String?,
      fallback: GameSubtype.storyBuilder,
    );

    // Helper to safely get a string from dynamic json fields
    String? getString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) return value.join(' ');
      return value.toString();
    }

    // Helper to parse lists safely and prevent TypeErrors
    List<String>? parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    return EliteMasteryQuestModel(
      id: json['id'] as String? ?? '',
      type: subtype.category,
      instruction: json['instruction'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      subtype: subtype,
      interactionType: InteractionType.fromString(
        json['interactionType'] as String?,
        fallback: InteractionType.choice,
      ),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (json['coinReward'] as num?)?.toInt() ?? 10,
      options: parseStringList(json['options']),
      correctAnswerIndex: (json['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: getString(json['correctAnswer']),
      hint: json['hint'] as String?,
      visualConfig: json['visual_config'] != null
          ? VisualConfig.fromJson(
              Map<String, dynamic>.from(json['visual_config'] as Map),
            )
          : null,
      sentences: parseStringList(json['sentences']),
      // FIX: previously always round-tripped through `e.toString()` then
      // `int.tryParse`. For a genuine int (e.g. `3`) this works, but if a
      // value ever arrives as a double (e.g. `3.0`), `.toString()` produces
      // `"3.0"`, which `int.tryParse` cannot parse — silently falling back
      // to `0` instead of `3`. Handling `num` directly avoids that
      // silent-data-corruption path; the string fallback remains for any
      // other representation.
      correctOrder: json['correctOrder'] != null
          ? (json['correctOrder'] as List)
                .map(
                  (e) =>
                      e is num ? e.toInt() : (int.tryParse(e.toString()) ?? 0),
                )
                .toList()
          : null,
      idiom: getString(json['idiom']),
      word: getString(json['word']),
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble(),
      audioUrl: getString(json['audioUrl']),
      textToSpeak: getString(json['textToSpeak']),
      text: getString(json['text'] ?? json['textToSpeak']),
      // FIX: every Idiom Match quest carries a `question` field (the
      // scenario text the player reads before picking an idiom) which was
      // never parsed. Without it, IdiomMatchScreen's
      // `quest.question != null && quest.question!.isNotEmpty` check was
      // always false, so the scenario prompt never rendered at all.
      question: json['question'] as String?,
      // Pedagogical "why" note. Present on every curriculum quest (verified
      // across all Accent Shadowing batches) but previously never parsed —
      // it was silently discarded by every prior version of this model.
      explanation: getString(json['explanation']),
      shadowingFocus: getString(json['shadowingFocus']),
      usageContext: getString(json['usageContext']),
      spellingRule: getString(json['spellingRule']),
      sequenceLogic: getString(json['sequenceLogic']),
      plotStructure: getString(json['plotStructure']),
      idiomOrigin: getString(json['idiomOrigin']),
      visualMetaphor: getString(json['visualMetaphor']),
      difficultyTier: getString(json['difficultyTier']),
      targetAccent: getString(json['targetAccent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instruction': instruction,
      'difficulty': difficulty,
      'subtype': subtype?.name,
      'interactionType': interactionType.name,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'correctAnswer': correctAnswer,
      'hint': hint,
      'sentences': sentences,
      'correctOrder': correctOrder,
      'idiom': idiom,
      'word': word,
      'speedMultiplier': speedMultiplier,
      'audioUrl': audioUrl,
      'textToSpeak': textToSpeak,
      'text': text,
      'question': question,
      'explanation': explanation,
      'shadowingFocus': shadowingFocus,
      'usageContext': usageContext,
      'spellingRule': spellingRule,
      'sequenceLogic': sequenceLogic,
      'plotStructure': plotStructure,
      'idiomOrigin': idiomOrigin,
      'visualMetaphor': visualMetaphor,
      'difficultyTier': difficultyTier,
      'targetAccent': targetAccent,
    };
  }
}
