import '../../domain/entities/vocabulary_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class VocabularyQuestModel extends VocabularyQuest {
  const VocabularyQuestModel({
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
    super.word,
    super.definition,
    super.synonym,
    super.antonym,
    super.contextSentence,
    super.explanation,
    super.audioUrl,
    super.passage,
    super.synonyms,
    super.antonyms,
    super.textToSpeak,
    super.prompt,
  });

  factory VocabularyQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.flashcards,
    );
    return VocabularyQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction:
          map['instruction'] ?? map['question'] ?? 'Choose the correct answer.',
      difficulty: map['difficulty'] ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == (map['interactionType'] ?? 'choice'),
        orElse: () => InteractionType.choice,
      ),
      xpReward: map['xpReward'] ?? 10,
      coinReward: map['coinReward'] ?? 5,
      livesAllowed: map['livesAllowed'],
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : null,
      correctAnswerIndex:
          map['correctAnswerIndex'] ?? map['correctAnswerIndex'],
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      word: map['word'] ?? map['targetWord'] ?? map['topic'],
      definition: map['definition'] ?? map['meaning'],
      synonym: map['synonym'],
      antonym: map['antonym'],
      contextSentence:
          map['contextSentence'] ?? map['example'] ?? map['sentence'],
      explanation: map['explanation'],
      audioUrl: map['audioUrl'],
      passage: map['passage'],
      synonyms: map['synonyms'] != null
          ? List<String>.from(map['synonyms'])
          : null,
      antonyms: map['antonyms'] != null
          ? List<String>.from(map['antonyms'])
          : null,
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
      'word': word,
      'definition': definition,
      'synonym': synonym,
      'antonym': antonym,
      'contextSentence': contextSentence,
      'explanation': explanation,
      'audioUrl': audioUrl,
      'passage': passage,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'textToSpeak': textToSpeak,
      'prompt': prompt,
    };
  }
}
