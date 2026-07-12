import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

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
    super.correctAnswerCategory,
    super.question,
    super.sentence,
    super.targetWord,
    super.hint,
    super.visualConfig,
    super.textToSpeak,
    super.explanation,
    super.missingWord,
    super.prompt,
    super.sampleAnswer,
    super.translation,
    super.situationText,
    super.sceneText,
    super.acceptedSynonyms,
    super.phoneticHint,
    super.meaning,
    super.sampleUsage,
    super.partnerDialogue,
    super.targetPhoneme,
    super.expression,
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

    // Helper to safely get a string list with type resilience
    List<String>? getList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    return SpeakingQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Speak the words.',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      interactionType: InteractionType.fromString(
        map['interactionType'] as String?,
        fallback: InteractionType.speech,
      ),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (map['coinReward'] as num?)?.toInt() ?? 10,
      livesAllowed: (map['livesAllowed'] as num?)?.toInt() ?? 3,
      options: getList(map['options']),
      correctAnswerIndex: (map['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: getString(map['correctAnswer']),
      correctAnswerCategory: getString(map['correctAnswerCategory']),
      question: getString(map['question']),
      sentence: getString(map['sentence']),
      targetWord: getString(map['targetWord']),
      hint: map['hint'] as String?,
      visualConfig: map['visual_config'] != null
          ? VisualConfig.fromJson(
              Map<String, dynamic>.from(map['visual_config']),
            )
          : null,
      textToSpeak: getString(
        map['textToSpeak'] ?? map['text'] ?? map['sentence'] ?? map['question'],
      ),
      prompt: getString(map['prompt']),
      sampleAnswer: getString(map['sampleAnswer']),
      translation: getString(map['translation']),
      situationText: map['situationText'] ?? map['situation'],
      sceneText: map['sceneText'] ?? map['scene'],
      acceptedSynonyms: getList(map['acceptedSynonyms']),
      phoneticHint: map['phoneticHint'] ?? map['phonetic'],
      meaning: map['meaning'] as String?,
      sampleUsage: map['sampleUsage'] as String?,
      missingWord: map['missingWord'] as String?,
      partnerDialogue: map['partnerDialogue'] as String?,
      targetPhoneme: map['targetPhoneme'] as String?,
      expression: map['expression'] as String?,
      explanation: map['explanation'] as String?,
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
      'correctAnswerCategory': correctAnswerCategory,
      'question': question,
      'sentence': sentence,
      'targetWord': targetWord,
      'hint': hint,
      'textToSpeak': textToSpeak,
      'visual_config': visualConfig?.toJson(),
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
      'prompt': prompt,
      'sampleAnswer': sampleAnswer,
      'translation': translation,
    };
  }

  SpeakingQuestModel copyWith({
    String? id,
    QuestType? type,
    String? instruction,
    int? difficulty,
    GameSubtype? subtype,
    InteractionType? interactionType,
    int? xpReward,
    int? coinReward,
    int? livesAllowed,
    List<String>? options,
    int? correctAnswerIndex,
    String? correctAnswer,
    String? correctAnswerCategory,
    String? question,
    String? sentence,
    String? targetWord,
    String? hint,
    String? explanation,
    String? textToSpeak,
    VisualConfig? visualConfig,
    String? missingWord,
    String? prompt,
    String? sampleAnswer,
    String? translation,
    String? situationText,
    String? sceneText,
    List<String>? acceptedSynonyms,
    String? phoneticHint,
    String? meaning,
    String? sampleUsage,
    String? partnerDialogue,
    String? targetPhoneme,
    String? expression,
  }) {
    return SpeakingQuestModel(
      id: id ?? this.id,
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      difficulty: difficulty ?? this.difficulty,
      subtype: subtype ?? this.subtype,
      interactionType: interactionType ?? this.interactionType,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      livesAllowed: livesAllowed ?? this.livesAllowed,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      correctAnswerCategory:
          correctAnswerCategory ?? this.correctAnswerCategory,
      question: question ?? this.question,
      sentence: sentence ?? this.sentence,
      targetWord: targetWord ?? this.targetWord,
      hint: hint ?? this.hint,
      explanation: explanation ?? this.explanation,
      textToSpeak: textToSpeak ?? this.textToSpeak,
      visualConfig: visualConfig ?? this.visualConfig,
      missingWord: missingWord ?? this.missingWord,
      prompt: prompt ?? this.prompt,
      sampleAnswer: sampleAnswer ?? this.sampleAnswer,
      translation: translation ?? this.translation,
      situationText: situationText ?? this.situationText,
      sceneText: sceneText ?? this.sceneText,
      acceptedSynonyms: acceptedSynonyms ?? this.acceptedSynonyms,
      phoneticHint: phoneticHint ?? this.phoneticHint,
      meaning: meaning ?? this.meaning,
      sampleUsage: sampleUsage ?? this.sampleUsage,
      partnerDialogue: partnerDialogue ?? this.partnerDialogue,
      targetPhoneme: targetPhoneme ?? this.targetPhoneme,
      expression: expression ?? this.expression,
    );
  }
}
