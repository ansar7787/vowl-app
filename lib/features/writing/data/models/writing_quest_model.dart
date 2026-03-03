import '../../domain/entities/writing_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class WritingQuestModel extends WritingQuest {
  const WritingQuestModel({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.writing,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.prefix,
    super.suffix,
    super.situation,
    super.minWords,
    super.story,
    super.requiredPoints,
    super.passage,
    super.question,
    super.missingWord,
    super.prompt,
    super.sampleAnswer,
    super.explanation,
    super.shuffledWords,
    super.correctOrder,
    super.dayDescription,
    super.context,
    super.partialSentence,
    super.completion,
  });

  factory WritingQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtypeStr = map['subtype'] ?? map['gameType'] ?? '';
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == subtypeStr,
      orElse: () => GameSubtype.sentenceBuilder,
    );
    return WritingQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Write the response.',
      difficulty: map['difficulty'] ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == (map['interactionType'] ?? 'writing'),
        orElse: () => InteractionType.writing,
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
      prefix: map['prefix'],
      suffix: map['suffix'],
      situation: map['situation'],
      minWords: map['minWords'],
      story: map['story'],
      requiredPoints: map['requiredPoints'] != null
          ? List<String>.from(map['requiredPoints'])
          : null,
      passage: map['passage'],
      question: map['question'],
      missingWord: map['missingWord'],
      prompt: map['prompt'] ?? map['journalPrompt'],
      sampleAnswer: map['sampleAnswer'],
      explanation: map['explanation'],
      shuffledWords: map['shuffledWords'] != null
          ? List<String>.from(map['shuffledWords'])
          : (map['shuffledSentences'] != null
                ? List<String>.from(map['shuffledSentences'])
                : null),
      correctOrder: map['correctOrder'] != null
          ? List<int>.from(map['correctOrder'])
          : null,
      dayDescription: map['dayDescription'],
      context: map['context'],
      partialSentence: map['partialSentence'],
      completion: map['completion'],
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
      'prefix': prefix,
      'suffix': suffix,
      'situation': situation,
      'minWords': minWords,
      'story': story,
      'requiredPoints': requiredPoints,
      'passage': passage,
      'question': question,
      'missingWord': missingWord,
      'prompt': prompt,
      'sampleAnswer': sampleAnswer,
      'explanation': explanation,
      'shuffledWords': shuffledWords,
      'correctOrder': correctOrder,
      'dayDescription': dayDescription,
      'context': context,
      'partialSentence': partialSentence,
      'completion': completion,
    };
  }
}
