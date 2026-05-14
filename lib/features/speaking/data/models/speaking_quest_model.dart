import '../../domain/entities/speaking_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class SpeakingQuestModel extends SpeakingQuest {
  const SpeakingQuestModel({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.speech,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.visualConfig,
    super.textToSpeak,
    super.situationText,
    super.sceneText,
    super.acceptedSynonyms,
    super.phoneticHint,
    super.meaning,
    super.sampleUsage,
    super.missingWord,
    super.partnerDialogue,
    super.targetPhoneme,
    super.expression,
    super.explanation,
  });

  factory SpeakingQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.repeatSentence,
    );

    // Helper to safely get a string from either a String or a List of Strings
    String? getString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) return value.join(' ');
      return value.toString();
    }

    return SpeakingQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Speak the words.',
      difficulty: map['difficulty'] ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == (map['interactionType'] ?? 'speech'),
        orElse: () => InteractionType.speech,
      ),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (map['coinReward'] as num?)?.toInt() ?? 5,
      livesAllowed: (map['livesAllowed'] as num?)?.toInt() ?? 3,
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswerIndex: map['correctAnswerIndex'],
      correctAnswer: getString(map['correctAnswer']),
      hint: map['hint'],
      visualConfig: map['visual_config'] != null
          ? VisualConfig.fromJson(Map<String, dynamic>.from(map['visual_config']))
          : null,
      textToSpeak: getString(map['textToSpeak'] ?? map['text'] ?? map['sentence'] ?? map['question']),
      situationText: map['situationText'] ?? map['situation'],
      sceneText: map['sceneText'] ?? map['scene'],
      acceptedSynonyms: map['acceptedSynonyms'] != null
          ? List<String>.from(map['acceptedSynonyms'])
          : null,
      phoneticHint: map['phoneticHint'] ?? map['phonetic'],
      meaning: map['meaning'],
      sampleUsage: map['sampleUsage'],
      missingWord: map['missingWord'],
      partnerDialogue: map['partnerDialogue'],
      targetPhoneme: map['targetPhoneme'],
      expression: map['expression'],
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
      'textToSpeak': textToSpeak,
      'situationText': situationText,
      'sceneText': sceneText,
      'acceptedSynonyms': acceptedSynonyms,
      'phoneticHint': phoneticHint,
      'meaning': meaning,
      'sampleUsage': sampleUsage,
      'missingWord': missingWord,
      'partnerDialogue': partnerDialogue,
      'targetPhoneme': targetPhoneme,
      'expression': expression,
      'explanation': explanation,
    };
  }
}

