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
    super.visualConfig,
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
    super.subject,
    super.recipient,
    super.essayTopic,
  });

  factory WritingQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtypeStr = map['subtype'] ?? map['gameType'] ?? '';
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == subtypeStr,
      orElse: () => GameSubtype.sentenceBuilder,
    );

    // Helper to safely get a string from either a String or a List of Strings
    String? getString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) return value.join(' ');
      return value.toString();
    }

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
      prefix: map['prefix'],
      suffix: map['suffix'],
      situation: map['situation'] ?? map['context'] ?? map['story'],
      minWords: map['minWords'],
      story: map['story'] ?? map['passage'] ?? map['text'],
      requiredPoints: map['requiredPoints'] != null
          ? List<String>.from(map['requiredPoints'])
          : null,
      passage: map['passage'] ?? map['text'] ?? map['content'] ?? map['story'],
      question: map['question'] ?? map['instruction'] ?? map['prompt'],
      missingWord: map['missingWord'],
      prompt: map['prompt'] ?? map['journalPrompt'] ?? map['question'] ?? map['instruction'],
      sampleAnswer: getString(map['sampleAnswer'] ?? map['correctAnswer']),
      explanation: map['explanation'],
      shuffledWords: map['shuffledWords'] != null
          ? List<String>.from(map['shuffledWords'])
          : (map['shuffledSentences'] != null
              ? List<String>.from(map['shuffledSentences'])
              : (map['options'] != null ? List<String>.from(map['options']) : null)),
      correctOrder: map['correctOrder'] != null
          ? (map['correctOrder'] as List).map((e) => int.tryParse(e.toString()) ?? 0).toList()
          : null,
      dayDescription: map['dayDescription'],
      context: map['context'] ?? map['situation'],
      partialSentence: map['partialSentence'] ?? map['sentence'],
      completion: map['completion'],
      subject: map['subject'],
      recipient: map['recipient'],
      essayTopic: map['essayTopic'],
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
      'subject': subject,
      'recipient': recipient,
      'essayTopic': essayTopic,
    };
  }
}

