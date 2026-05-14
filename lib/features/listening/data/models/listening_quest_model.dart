import '../../domain/entities/listening_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class ListeningQuestModel extends ListeningQuest {
  const ListeningQuestModel({
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
    super.audioUrl,
    super.question,
    super.statement,
    super.textWithBlanks,
    super.audioOptions,
    super.transcript,
    super.targetEmotion,
    super.textToSpeak,
    super.missingWord,
    super.targetDetail,
    super.impliedMeaning,
    super.location,
    super.shuffledSentences,
    super.correctOrder,
    super.explanation,
  });

  factory ListeningQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.audioFillBlanks,
    );
    return ListeningQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Listen and answer.',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
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
      correctAnswerIndex: (map['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      visualConfig: map['visual_config'] != null ? VisualConfig.fromJson(Map<String, dynamic>.from(map['visual_config'])) : null,
      audioUrl: map['audioUrl'] ?? map['ambientAudioUrl'],
      question: map['question'] ?? map['sentence'] ?? map['statement'],
      statement: map['statement'] ?? map['text'],
      textWithBlanks: map['textWithBlanks'] ?? map['sentenceWithBlank'],
      audioOptions: map['audioOptions'] != null
          ? List<String>.from(map['audioOptions'])
          : null,
      transcript: map['transcript'] ?? map['text'] ?? map['sentence'] ?? map['audioTranscript'],
      targetEmotion: map['targetEmotion'],
      textToSpeak: (map['textToSpeak'] ?? map['transcript'] ?? map['text'] ?? map['sentence']) as String?,
      missingWord: map['missingWord'] as String?,
      targetDetail: map['targetDetail'],
      impliedMeaning: map['impliedMeaning'],
      location: map['location'],
      shuffledSentences: map['shuffledSentences'] != null ? List<String>.from(map['shuffledSentences']) : null,
      correctOrder: map['correctOrder'] != null ? List<int>.from(map['correctOrder']) : null,
      explanation: map['explanation'],
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
      'audioUrl': audioUrl,
      'question': question,
      'statement': statement,
      'textWithBlanks': textWithBlanks,
      'audioOptions': audioOptions,
      'transcript': transcript,
      'targetEmotion': targetEmotion,
      'targetDetail': targetDetail,
      'impliedMeaning': impliedMeaning,
      'location': location,
      'shuffledSentences': shuffledSentences,
      'correctOrder': correctOrder,
      'explanation': explanation,
    };
  }
}

