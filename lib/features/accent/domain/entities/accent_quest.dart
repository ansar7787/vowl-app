import 'package:vowl/core/domain/entities/game_quest.dart';

class AccentQuest extends GameQuest {
  final String? word;
  final String? phoneticHint;
  final String? targetWord;
  final String? question;
  final String? prompt;
  final String? sampleAnswer;
  final String? explanation;
  final String? audioUrl;
  final List<String>? words;
  final List<int>? intonationMap;
  final List<String>? syllables;
  final double? targetSpeed;
  final List<int>? pitchPatterns;
  final String? sentence;
  final String? stressPattern;
  final String? word1;
  final String? word2;
  final String? ipa1;
  final String? ipa2;
  final String? mouthPosition;
  final String? slowForm;
  final String? accentName;

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
    this.targetWord,
    this.question,
    super.textToSpeak,
    super.visualConfig,
    this.prompt,
    this.sampleAnswer,
    this.explanation,
    this.audioUrl,
    this.words,
    this.intonationMap,
    this.syllables,
    this.targetSpeed,
    this.pitchPatterns,
    this.sentence,
    this.stressPattern,
    this.word1,
    this.word2,
    this.ipa1,
    this.ipa2,
    this.mouthPosition,
    this.slowForm,
    this.accentName,
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
      sentence: sentence ?? this.sentence,
      stressPattern: stressPattern ?? this.stressPattern,
      word1: word1 ?? this.word1,
      word2: word2 ?? this.word2,
      ipa1: ipa1 ?? this.ipa1,
      ipa2: ipa2 ?? this.ipa2,
      mouthPosition: mouthPosition ?? this.mouthPosition,
      slowForm: slowForm ?? this.slowForm,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    word,
    phoneticHint,
    targetWord,
    question,
    prompt,
    sampleAnswer,
    explanation,
    audioUrl,
    words,
    intonationMap,
    syllables,
    targetSpeed,
    pitchPatterns,
    sentence,
    stressPattern,
    word1,
    word2,
    ipa1,
    ipa2,
    mouthPosition,
    slowForm,
  ];
}

