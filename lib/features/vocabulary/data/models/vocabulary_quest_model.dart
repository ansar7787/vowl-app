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
    super.visualConfig,
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
    super.topicEmoji,
    super.topicFact,
    super.rootWord,
    super.prefix,
    super.suffix,
    super.topicBuckets,
  });

  factory VocabularyQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.flashcards,
    );

    // 1. Extract Options
    final rawOptions = map['options'] != null
        ? List<String>.from(map['options'])
        : (map['choices'] != null ? List<String>.from(map['choices']) : null);

    // 2. Shuffle Options and Update Correct Index
    List<String>? shuffledOptions;
    int? newCorrectIndex = (map['correctAnswerIndex'] as num?)?.toInt();

    if (rawOptions != null &&
        newCorrectIndex != null &&
        newCorrectIndex >= 0 &&
        newCorrectIndex < rawOptions.length) {
      final correctOption = rawOptions[newCorrectIndex];
      shuffledOptions = List<String>.from(rawOptions)..shuffle();
      newCorrectIndex = shuffledOptions.indexOf(correctOption);
    } else {
      shuffledOptions = rawOptions;
    }

    return VocabularyQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction:
          map['instruction'] ?? map['question'] ?? 'Choose the correct answer.',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == (map['interactionType'] ?? 'choice'),
        orElse: () => InteractionType.choice,
      ),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (map['coinReward'] as num?)?.toInt() ?? 5,
      livesAllowed: (map['livesAllowed'] as num?)?.toInt() ?? 3,
      options: shuffledOptions,
      correctAnswerIndex: newCorrectIndex,
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      visualConfig: map['visual_config'] != null
          ? VisualConfig.fromJson(
              Map<String, dynamic>.from(map['visual_config']))
          : null,
      word: map['word'] ??
          map['targetWord'] ??
          map['topic'] ??
          (subtype == GameSubtype.wordFormation
              ? _extractRootWord(map['question'] ?? map['instruction'] ?? '')
              : map['transcript']),
      definition: map['definition'] ?? map['meaning'],
      synonym: map['synonym'],
      antonym: map['antonym'],
      contextSentence: map['contextSentence'] ??
          map['example'] ??
          map['sentence'] ??
          map['transcript'] ??
          map['passage'],
      explanation: map['explanation'] ??
          (subtype == GameSubtype.wordFormation
              ? "Synthesis complete. The root was modified to form the correct word class."
              : (subtype == GameSubtype.topicVocab
                  ? "Nexus synced. This term is core to the topic's data structure."
                  : null)),
      audioUrl: map['audioUrl'],
      passage: map['passage'] ?? map['contextSentence'] ?? map['text'],
      synonyms:
          map['synonyms'] != null ? List<String>.from(map['synonyms']) : null,
      antonyms:
          map['antonyms'] != null ? List<String>.from(map['antonyms']) : null,
      textToSpeak: map['textToSpeak'] ??
          map['word'] ??
          map['definition'] ??
          map['contextSentence'],
      prompt: map['prompt'] ?? map['question'] ?? map['instruction'],
      topicEmoji: map['topic_emoji'] ?? map['topicEmoji'],
      topicFact: map['topic_fact'] ?? map['topicFact'],
      rootWord: map['rootWord'],
      prefix: map['prefix'],
      suffix: map['suffix'],
      topicBuckets: map['topicBuckets'] != null ? List<String>.from(map['topicBuckets']) : null,
    );
  }

  static String? _extractRootWord(String text) {
    if (text.isEmpty) return null;
    final regExp = RegExp(r"'(.*?)'");
    final match = regExp.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }
    return null;
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
      'topic_emoji': topicEmoji,
      'topic_fact': topicFact,
      'rootWord': rootWord,
      'prefix': prefix,
      'suffix': suffix,
      'topicBuckets': topicBuckets,
    };
  }
}
