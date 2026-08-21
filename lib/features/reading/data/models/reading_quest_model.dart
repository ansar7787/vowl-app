import '../../domain/entities/reading_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class ReadingQuestModel extends ReadingQuest {
  const ReadingQuestModel({
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
    super.passage,
    super.question,
    super.highlightedWord,
    super.statement,
    super.shuffledSentences,
    super.correctOrder,
    super.pairs,
    super.phoneticHint,
    super.targetWord,
    super.explanation,
    super.textToSpeak,
    super.prompt,
    super.keywords,
    super.timeLimit,
    super.targetItem,
    super.passageWordCount,
    super.wordInContext,
    super.evidenceLine,
    super.transitionWords,
    super.wpmTarget,
    super.whyThisTitle,
    super.paragraphTopic,
    super.keyPoints,
    super.clueWords,
    super.logicChain,
    super.wordCategory,
    super.targetInfo,
  });

  factory ReadingQuestModel.fromJson(Map<String, dynamic> map, String id) {
    // Optimized O(1) constant-time enum parsing
    final subtype = GameSubtype.fromString(
      map['subtype'] as String?,
      fallback: GameSubtype.readAndAnswer,
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

    return ReadingQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] as String? ?? 'Read and answer.',
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
      passage: getString(
        map['passage'] ??
            map['text'] ??
            map['content'] ??
            map['story'] ??
            map['sentence'],
      ),
      question: map['question'] as String? ?? map['instruction'] as String?,
      highlightedWord:
          map['highlightedWord'] as String? ?? map['targetWord'] as String?,
      statement: map['statement'] as String? ?? map['text'] as String?,
      shuffledSentences: parseStringList(map['shuffledSentences']),
      correctOrder: map['correctOrder'] != null
          ? (map['correctOrder'] as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .toList()
          : null,
      pairs: map['pairs'] != null
          ? List<Map<String, String>>.from(
              (map['pairs'] as List).map(
                (e) => Map<String, String>.from(e as Map),
              ),
            )
          : null,
      phoneticHint:
          map['phoneticHint'] as String? ?? map['phonetic'] as String?,
      targetWord: map['targetWord'] as String? ?? map['word'] as String?,
      explanation: map['explanation'] as String?,
      textToSpeak: getString(
        map['textToSpeak'] ?? map['passage'] ?? map['text'],
      ),
      prompt: map['prompt'] as String?,
      keywords: parseStringList(map['keywords']),
      timeLimit: (map['timeLimit'] as num?)?.toInt(),
      targetItem: map['targetItem'] as String?,
      passageWordCount: (map['passageWordCount'] as num?)?.toInt(),
      wordInContext: getString(map['wordInContext']),
      evidenceLine: getString(map['evidenceLine']),
      transitionWords: parseStringList(map['transitionWords']),
      wpmTarget: (map['wpmTarget'] as num?)?.toInt() ?? (map['wpm_target'] as num?)?.toInt(),
      whyThisTitle: getString(map['whyThisTitle']),
      paragraphTopic: getString(map['paragraphTopic']),
      keyPoints: parseStringList(map['keyPoints']),
      clueWords: parseStringList(map['clueWords']),
      logicChain: parseStringList(map['logicChain']),
      wordCategory: getString(map['wordCategory']),
      targetInfo: getString(map['targetInfo']),
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
      'passage': passage,
      'question': question,
      'highlightedWord': highlightedWord,
      'statement': statement,
      'shuffledSentences': shuffledSentences,
      'correctOrder': correctOrder,
      'pairs': pairs,
      'phoneticHint': phoneticHint,
      'targetWord': targetWord,
      'explanation': explanation,
      'textToSpeak': textToSpeak,
      'prompt': prompt,
      'keywords': keywords,
      'timeLimit': timeLimit,
      'targetItem': targetItem,
      'passageWordCount': passageWordCount,
      'wordInContext': wordInContext,
      'evidenceLine': evidenceLine,
      'transitionWords': transitionWords,
      'wpmTarget': wpmTarget,
      'whyThisTitle': whyThisTitle,
      'paragraphTopic': paragraphTopic,
      'keyPoints': keyPoints,
      'clueWords': clueWords,
      'logicChain': logicChain,
      'wordCategory': wordCategory,
      'targetInfo': targetInfo,
    };
  }
}
