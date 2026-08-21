import '../../domain/entities/grammar_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class GrammarQuestModel extends GrammarQuest {
  const GrammarQuestModel({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.choice,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.visualConfig,
    super.sentence,
    super.verb,
    super.word,
    super.targetTense,
    super.secondarySentence,
    super.firstClause,
    super.secondClause,
    super.connectorToUse,
    super.sentenceWithBlank,
    super.articleToInsert,
    super.targetWord,
    super.passage,
    super.passiveSentence,
    super.activeSentence,
    super.shuffledWords,
    super.correctOrder,
    super.explanation,
    super.incorrectPart,
    super.correctedPart,
    super.grammarRule,
    super.ruleExplanation,
    super.errorHighlight,
    super.structureType,
    super.timelinePosition,
    super.transformations,
    super.subjectType,
    super.connectorCategory,
    super.activeVoice,
    super.passiveVoice,
  });

  factory GrammarQuestModel.fromJson(Map<String, dynamic> map, String id) {
    // Optimized O(1) constant-time enum parsing
    final subtype = GameSubtype.fromString(
      map['subtype'] as String?,
      fallback: GameSubtype.grammarQuest,
    );

    // Helper to safely get a string from either a String or a List of Strings
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

    return GrammarQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction:
          map['instruction'] as String? ??
          map['question'] as String? ??
          'Solve the grammar puzzle.',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      interactionType: InteractionType.fromString(
        map['interactionType'] as String?,
        fallback: InteractionType.choice,
      ),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (map['coinReward'] as num?)?.toInt() ?? 5,
      livesAllowed: (map['livesAllowed'] as num?)?.toInt() ?? 3,
      options: parseStringList(map['options'] ?? map['choices']),
      correctAnswerIndex: (map['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: getString(map['correctAnswer']),
      hint: map['hint'] as String?,
      visualConfig: map['visual_config'] != null
          ? VisualConfig.fromJson(
              Map<String, dynamic>.from(map['visual_config'] as Map),
            )
          : null,
      sentence:
          map['sentence'] as String? ??
          map['question'] as String? ??
          map['text'] as String?,
      verb: map['verb'] as String?,
      word: map['word'] as String?,
      targetTense: map['targetTense'] as String?,
      secondarySentence: map['secondarySentence'] as String?,
      firstClause: map['firstClause'] as String?,
      secondClause: map['secondClause'] as String?,
      connectorToUse: map['connectorToUse'] as String?,
      sentenceWithBlank:
          map['sentenceWithBlank'] as String? ?? map['sentence'] as String?,
      articleToInsert: map['articleToInsert'] as String?,
      targetWord: map['targetWord'] as String?,
      passage: map['passage'] as String?,
      passiveSentence: map['passiveSentence'] as String?,
      activeSentence: map['activeSentence'] as String?,
      shuffledWords: parseStringList(map['shuffledWords']),
      correctOrder: map['correctOrder'] != null
          ? (map['correctOrder'] as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .toList()
          : null,
      explanation: map['explanation'] as String?,
      incorrectPart: map['incorrectPart'] as String?,
      correctedPart: map['correctedPart'] as String?,
      grammarRule: getString(map['grammarRule']),
      ruleExplanation: getString(map['ruleExplanation']),
      errorHighlight: getString(map['errorHighlight']),
      structureType: getString(map['structureType']),
      timelinePosition: getString(map['timelinePosition']),
      transformations: map['transformations'] != null ? List<String>.from(map['transformations']) : null,
      subjectType: getString(map['subjectType']),
      connectorCategory: getString(map['connectorCategory']),
      activeVoice: getString(map['activeVoice']),
      passiveVoice: getString(map['passiveVoice']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instruction': instruction,
      'difficulty': difficulty,
      'subtype': subtype?.name,
      'interactionType': interactionType.name,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'livesAllowed': livesAllowed,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'correctAnswer': correctAnswer,
      'hint': hint,
      'sentence': sentence,
      'verb': verb,
      'word': word,
      'targetTense': targetTense,
      'secondarySentence': secondarySentence,
      'firstClause': firstClause,
      'secondClause': secondClause,
      'connectorToUse': connectorToUse,
      'sentenceWithBlank': sentenceWithBlank,
      'articleToInsert': articleToInsert,
      'targetWord': targetWord,
      'passage': passage,
      'passiveSentence': passiveSentence,
      'activeSentence': activeSentence,
      'shuffledWords': shuffledWords,
      'correctOrder': correctOrder,
      'explanation': explanation,
      'incorrectPart': incorrectPart,
      'correctedPart': correctedPart,
      'grammarRule': grammarRule,
      'ruleExplanation': ruleExplanation,
      'errorHighlight': errorHighlight,
      'structureType': structureType,
      'timelinePosition': timelinePosition,
      'transformations': transformations,
      'subjectType': subjectType,
      'connectorCategory': connectorCategory,
      'activeVoice': activeVoice,
      'passiveVoice': passiveVoice,
    };
  }
}
