import '../../domain/entities/accent_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class AccentQuestModel extends AccentQuest {
  const AccentQuestModel({
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
    super.word,
    super.phoneticHint,
    super.targetWord,
    super.question,
    super.textToSpeak,
    super.prompt,
    super.sampleAnswer,
    super.explanation,
    super.audioUrl,
    super.words,
    super.intonationMap,
    super.syllables,
    super.targetSpeed,
    super.pitchPatterns,
    super.sentence,
    super.stressPattern,
    super.word1,
    super.word2,
    super.ipa1,
    super.ipa2,
    super.mouthPosition,
    super.slowForm,
  });

  factory AccentQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.minimalPairs,
    );
    return AccentQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Mimic the accent.',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == (map['interactionType'] ?? 'speech'),
        orElse: () => InteractionType.speech,
      ),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (map['coinReward'] as num?)?.toInt() ?? 5,
      livesAllowed: (map['livesAllowed'] as num?)?.toInt() ?? 3,
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : null,
      correctAnswerIndex: (map['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      word: map['word'],
      phoneticHint: map['phoneticHint'] ?? map['phonetic'],
      targetWord: map['targetWord'],
      question: map['question'],
      textToSpeak: map['textToSpeak'],
      prompt: map['prompt'],
      sampleAnswer: map['sampleAnswer'],
      explanation: map['explanation'],
      audioUrl: map['audioUrl'],
      words: map['words'] != null ? List<String>.from(map['words']) : null,
      intonationMap: map['intonationMap'] != null
          ? List<int>.from(map['intonationMap'])
          : null,
      syllables: map['syllables'] != null
          ? List<String>.from(map['syllables'])
          : null,
      targetSpeed: (map['targetSpeed'] as num?)?.toDouble(),
      pitchPatterns: map['pitchPatterns'] != null
          ? List<int>.from(map['pitchPatterns'])
          : null,
      sentence: map['sentence'],
      stressPattern: map['stressPattern'],
      word1: map['word1'],
      word2: map['word2'],
      ipa1: map['ipa1'],
      ipa2: map['ipa2'],
      mouthPosition: map['mouthPosition'],
      slowForm: map['slowForm'],
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
      'phoneticHint': phoneticHint,
      'targetWord': targetWord,
      'question': question,
      'textToSpeak': textToSpeak,
      'prompt': prompt,
      'sampleAnswer': sampleAnswer,
      'explanation': explanation,
      'audioUrl': audioUrl,
      'words': words,
      'intonationMap': intonationMap,
      'syllables': syllables,
      'targetSpeed': targetSpeed,
      'pitchPatterns': pitchPatterns,
      'sentence': sentence,
      'stressPattern': stressPattern,
      'word1': word1,
      'word2': word2,
      'ipa1': ipa1,
      'ipa2': ipa2,
      'mouthPosition': mouthPosition,
      'slowForm': slowForm,
    };
  }
}
