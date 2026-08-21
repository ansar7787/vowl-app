import 'package:vowl/core/domain/entities/game_quest.dart';

class AccentQuest extends GameQuest {
  final String? word;
  final String? phoneticHint;
  final String? prompt;
  final String? sampleAnswer;
  final String? audioUrl;
  final List<String>? words;
  final List<int>? intonationMap;
  final List<String>? syllables;
  final double? targetSpeed;
  final List<int>? pitchPatterns;
  final String? stressPattern;
  final String? word1;
  final String? word2;
  final String? ipa1;
  final String? ipa2;
  final String? mouthPosition;
  final String? slowForm;
  final String? accentName;
  final String? phoneticRule;
  final String? dialectNote;
  final String? pitchRule;
  final String? vowelTensionRule;
  final String? modulationPattern;
  final String? emphasisRule;
  final String? flowRule;
  final String? pacingRule;

  final String? stressRule;
  final String? emotionContext;
  final int? stressIndex;
  final String? linkingType;
  final double? speedLevel;
  final Map<String, dynamic>? vowelChart;
  final String? voicing;
  final String? airflow;
  final double? naturalSpeed;
  final double? clearSpeed;
  final String? dialectRegion;
  final String? phenomenonType;
  final String? spokenForm;

  const AccentQuest({
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
    this.word,
    this.phoneticHint,
    super.textToSpeak,
    super.visualConfig,
    this.prompt,
    this.sampleAnswer,
    super.explanation,
    this.audioUrl,
    this.words,
    this.intonationMap,
    this.syllables,
    this.targetSpeed,
    this.pitchPatterns,
    this.stressPattern,
    this.word1,
    this.word2,
    this.ipa1,
    this.ipa2,
    this.mouthPosition,
    this.slowForm,
    this.accentName,
    this.phoneticRule,
    this.dialectNote,
    this.pitchRule,
    this.vowelTensionRule,
    this.modulationPattern,
    this.emphasisRule,
    this.flowRule,
    this.pacingRule,
    this.stressRule,
    this.emotionContext,
    this.stressIndex,
    this.linkingType,
    this.speedLevel,
    this.vowelChart,
    this.voicing,
    this.airflow,
    this.naturalSpeed,
    this.clearSpeed,
    this.dialectRegion,
    this.phenomenonType,
    this.spokenForm,
    super.targetWord,
    super.question,
    super.sentence,
  });

  String? get phonetic => phoneticHint;

  AccentQuest copyWith({
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
    String? hint,
    String? word,
    String? phoneticHint,
    String? targetWord,
    String? question,
    String? textToSpeak,
    String? prompt,
    String? sampleAnswer,
    String? explanation,
    String? audioUrl,
    List<String>? words,
    List<int>? intonationMap,
    List<String>? syllables,
    double? targetSpeed,
    List<int>? pitchPatterns,
    String? sentence,
    String? stressPattern,
    String? word1,
    String? word2,
    String? ipa1,
    String? ipa2,
    String? mouthPosition,
    String? slowForm,
    String? accentName,
    String? phoneticRule,
    String? dialectNote,
    String? pitchRule,
    String? vowelTensionRule,
    String? modulationPattern,
    String? emphasisRule,
    String? flowRule,
    String? pacingRule,
    String? stressRule,
    String? emotionContext,
    int? stressIndex,
    String? linkingType,
    double? speedLevel,
    Map<String, dynamic>? vowelChart,
    String? voicing,
    String? airflow,
    double? naturalSpeed,
    double? clearSpeed,
    String? dialectRegion,
    String? phenomenonType,
    String? spokenForm,
  }) {
    return AccentQuest(
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
      hint: hint ?? this.hint,
      word: word ?? this.word,
      phoneticHint: phoneticHint ?? this.phoneticHint,
      targetWord: targetWord ?? this.targetWord,
      question: question ?? this.question,
      sentence: sentence ?? this.sentence,
      textToSpeak: textToSpeak ?? this.textToSpeak,
      prompt: prompt ?? this.prompt,
      sampleAnswer: sampleAnswer ?? this.sampleAnswer,
      explanation: explanation ?? this.explanation,
      audioUrl: audioUrl ?? this.audioUrl,
      words: words ?? this.words,
      intonationMap: intonationMap ?? this.intonationMap,
      syllables: syllables ?? this.syllables,
      targetSpeed: targetSpeed ?? this.targetSpeed,
      pitchPatterns: pitchPatterns ?? this.pitchPatterns,
      stressPattern: stressPattern ?? this.stressPattern,
      word1: word1 ?? this.word1,
      word2: word2 ?? this.word2,
      ipa1: ipa1 ?? this.ipa1,
      ipa2: ipa2 ?? this.ipa2,
      mouthPosition: mouthPosition ?? this.mouthPosition,
      slowForm: slowForm ?? this.slowForm,
      accentName: accentName ?? this.accentName,
      phoneticRule: phoneticRule ?? this.phoneticRule,
      dialectNote: dialectNote ?? this.dialectNote,
      pitchRule: pitchRule ?? this.pitchRule,
      vowelTensionRule: vowelTensionRule ?? this.vowelTensionRule,
      modulationPattern: modulationPattern ?? this.modulationPattern,
      emphasisRule: emphasisRule ?? this.emphasisRule,
      flowRule: flowRule ?? this.flowRule,
      pacingRule: pacingRule ?? this.pacingRule,
      stressRule: stressRule ?? this.stressRule,
      emotionContext: emotionContext ?? this.emotionContext,
      stressIndex: stressIndex ?? this.stressIndex,
      linkingType: linkingType ?? this.linkingType,
      speedLevel: speedLevel ?? this.speedLevel,
      vowelChart: vowelChart ?? this.vowelChart,
      voicing: voicing ?? this.voicing,
      airflow: airflow ?? this.airflow,
      naturalSpeed: naturalSpeed ?? this.naturalSpeed,
      clearSpeed: clearSpeed ?? this.clearSpeed,
      dialectRegion: dialectRegion ?? this.dialectRegion,
      phenomenonType: phenomenonType ?? this.phenomenonType,
      spokenForm: spokenForm ?? this.spokenForm,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    word,
    phoneticHint,
    targetWord,
    prompt,
    sampleAnswer,
    audioUrl,
    words,
    intonationMap,
    syllables,
    targetSpeed,
    pitchPatterns,
    stressPattern,
    word1,
    word2,
    ipa1,
    ipa2,
    mouthPosition,
    slowForm,
    accentName,
    phoneticRule,
    dialectNote,
    pitchRule,
    vowelTensionRule,
    modulationPattern,
    emphasisRule,
    flowRule,
    pacingRule,
    stressRule,
    emotionContext,
    stressIndex,
    linkingType,
    speedLevel,
    vowelChart,
    voicing,
    airflow,
    naturalSpeed,
    clearSpeed,
    dialectRegion,
    phenomenonType,
    spokenForm,
  ];
}
