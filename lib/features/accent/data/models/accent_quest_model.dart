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
    super.visualConfig,
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
    super.accentName,
    super.phoneticRule,
    super.dialectNote,
    super.pitchRule,
    super.vowelTensionRule,
    super.modulationPattern,
    super.emphasisRule,
    super.flowRule,
    super.pacingRule,
    super.stressRule,
  });

  factory AccentQuestModel.fromJson(Map<String, dynamic> map, String id) {
    // Optimized O(1) constant-time enum parsing
    final subtype = GameSubtype.fromString(
      map['subtype'] as String?,
      fallback: GameSubtype.minimalPairs,
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

    return AccentQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] as String? ?? 'Mimic the accent.',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      interactionType: InteractionType.fromString(
        map['interactionType'] as String?,
        fallback: InteractionType.speech,
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
      word: getString(map['word'] ?? map['targetWord']),
      phoneticHint: getString(
        map['phoneticHint'] ?? map['phonetic'] ?? map['ipa'],
      ),
      targetWord: getString(map['targetWord'] ?? map['word']),
      question: getString(
        map['question'] ?? map['prompt'] ?? map['instruction'],
      ),
      textToSpeak: getString(
        map['textToSpeak'] ??
            map['text'] ??
            map['sentence'] ??
            map['word'] ??
            map['targetWord'],
      ),
      prompt: getString(map['prompt'] ?? map['question'] ?? map['instruction']),
      sampleAnswer: getString(map['sampleAnswer']),
      explanation: getString(map['explanation']),
      audioUrl: getString(map['audioUrl']),
      words: parseStringList(map['words']),
      intonationMap: map['intonationMap'] != null
          ? (map['intonationMap'] as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .toList()
          : null,
      syllables: parseStringList(map['syllables']),
      targetSpeed: (map['targetSpeed'] as num?)?.toDouble(),
      pitchPatterns: map['pitchPatterns'] != null
          ? (map['pitchPatterns'] as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .toList()
          : null,
      sentence: getString(map['sentence'] ?? map['text'] ?? map['textToSpeak']),
      stressPattern: getString(map['stressPattern']),
      word1: getString(map['word1']),
      word2: getString(map['word2']),
      ipa1: getString(map['ipa1']),
      ipa2: getString(map['ipa2']),
      mouthPosition: getString(map['mouthPosition']),
      slowForm: getString(map['slowForm']),
      accentName: getString(map['accentName'] ?? map['dialect']),
      phoneticRule: getString(map['phoneticRule'] ?? map['rule']),
      dialectNote: getString(map['dialectNote']),
      pitchRule: getString(map['pitchRule']),
      vowelTensionRule: getString(map['vowelTensionRule']),
      modulationPattern: getString(map['modulationPattern']),
      emphasisRule: getString(map['emphasisRule']),
      flowRule: getString(map['flowRule']),
      pacingRule: getString(map['pacingRule']),
      stressRule: getString(map['stressRule']),
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
      'accentName': accentName,
      'phoneticRule': phoneticRule,
      'dialectNote': dialectNote,
      'pitchRule': pitchRule,
      'vowelTensionRule': vowelTensionRule,
      'modulationPattern': modulationPattern,
      'emphasisRule': emphasisRule,
      'flowRule': flowRule,
      'pacingRule': pacingRule,
      'stressRule': stressRule,
    };
  }
}
