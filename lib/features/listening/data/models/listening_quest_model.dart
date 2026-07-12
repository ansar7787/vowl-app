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
    super.imageUrl,
  });

  factory ListeningQuestModel.fromJson(Map<String, dynamic> map, String id) {
    // Optimized O(1) constant-time enum parsing
    final subtype = GameSubtype.fromString(
      map['subtype'] as String?,
      fallback: GameSubtype.audioFillBlanks,
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

    return ListeningQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] as String? ?? 'Listen and answer.',
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
      audioUrl: map['audioUrl'] as String? ?? map['ambientAudioUrl'] as String?,
      question:
          map['question'] as String? ??
          map['sentence'] as String? ??
          map['statement'] as String?,
      statement: map['statement'] as String? ?? map['text'] as String?,
      textWithBlanks:
          map['textWithBlanks'] as String? ??
          map['sentenceWithBlank'] as String?,
      audioOptions: parseStringList(map['audioOptions']),
      transcript:
          map['transcript'] as String? ??
          map['text'] as String? ??
          map['sentence'] as String? ??
          map['audioTranscript'] as String?,
      targetEmotion: map['targetEmotion'] as String?,
      textToSpeak: getString(
        map['textToSpeak'] ??
            map['transcript'] ??
            map['text'] ??
            map['sentence'],
      ),
      missingWord: map['missingWord'] as String?,
      targetDetail: map['targetDetail'] as String?,
      impliedMeaning: map['impliedMeaning'] as String?,
      location: map['location'] as String?,
      shuffledSentences: parseStringList(map['shuffledSentences']),
      correctOrder: map['correctOrder'] != null
          ? (map['correctOrder'] as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .toList()
          : null,
      explanation: map['explanation'] as String?,
      imageUrl: map['imageUrl'] as String? ?? map['image_url'] as String?,
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
      'imageUrl': imageUrl,
    };
  }
}
