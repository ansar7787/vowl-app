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
  });

  factory ReadingQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.readAndAnswer,
    );

    // Helper to safely get a string from either a String or a List of Strings
    String? getString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) return value.join(' ');
      return value.toString();
    }

    return ReadingQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Read and answer.',
      difficulty: map['difficulty'] ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == (map['interactionType'] ?? 'choice'),
        orElse: () => InteractionType.choice,
      ),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (map['coinReward'] as num?)?.toInt() ?? 5,
      livesAllowed: (map['livesAllowed'] as num?)?.toInt() ?? 3,
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : (map['choices'] != null ? List<String>.from(map['choices']) : null),
      correctAnswerIndex: map['correctAnswerIndex'],
      correctAnswer: getString(map['correctAnswer']),
      hint: map['hint'],
      visualConfig: map['visual_config'] != null
          ? VisualConfig.fromJson(Map<String, dynamic>.from(map['visual_config']))
          : null,
      passage: getString(map['passage'] ?? map['text'] ?? map['content'] ?? map['story'] ?? map['sentence']),
      question: map['question'] ?? map['instruction'],
      highlightedWord: map['highlightedWord'] ?? map['targetWord'],
      statement: map['statement'] ?? map['text'],
      shuffledSentences: map['shuffledSentences'] != null
          ? List<String>.from(map['shuffledSentences'])
          : null,
      correctOrder: map['correctOrder'] != null
          ? (map['correctOrder'] as List).map((e) => int.tryParse(e.toString()) ?? 0).toList()
          : null,
      pairs: map['pairs'] != null
          ? List<Map<String, String>>.from(
              (map['pairs'] as List).map((e) => Map<String, String>.from(e)),
            )
          : null,
      phoneticHint: map['phoneticHint'] ?? map['phonetic'],
      targetWord: map['targetWord'] ?? map['word'],
      explanation: map['explanation'],
      textToSpeak: getString(map['textToSpeak'] ?? map['passage'] ?? map['text']),
      prompt: map['prompt'],
      keywords: map['keywords'] != null ? List<String>.from(map['keywords']) : null,
      timeLimit: map['timeLimit'],
      targetItem: map['targetItem'],
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
    };
  }
}

