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
  });

  factory ReadingQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.readAndAnswer,
    );
    return ReadingQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Read and answer.',
      difficulty: map['difficulty'] ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == map['interactionType'],
        orElse: () => InteractionType.choice,
      ),
      xpReward: map['xpReward'] ?? 10,
      coinReward: map['coinReward'] ?? 5,
      livesAllowed: map['livesAllowed'],
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : null,
      correctAnswerIndex: map['correctAnswerIndex'],
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      passage: map['passage'],
      question: map['question'],
      highlightedWord: map['highlightedWord'],
      statement: map['statement'],
      shuffledSentences: map['shuffledSentences'] != null
          ? List<String>.from(map['shuffledSentences'])
          : null,
      correctOrder: map['correctOrder'] != null
          ? List<int>.from(map['correctOrder'])
          : null,
      pairs: map['pairs'] != null
          ? List<Map<String, String>>.from(
              (map['pairs'] as List).map((e) => Map<String, String>.from(e)),
            )
          : null,
      phoneticHint: map['phoneticHint'],
      targetWord: map['targetWord'] ?? map['word'],
      explanation: map['explanation'],
      textToSpeak: map['textToSpeak'],
      prompt: map['prompt'],
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
    };
  }
}
