import 'package:vowl/core/domain/entities/game_quest.dart';

class ListeningQuest extends GameQuest {
  final String? audioUrl;
  final String? transcription;
  final String? statement;
  final List<String>? shuffledSentences;
  final List<int>? correctOrder;
  final String? prompt;
  final String? textWithBlanks;
  final List<String>? audioOptions;
  final String? transcript;
  final String? targetEmotion;
  final String? targetDetail;
  final String? impliedMeaning;
  final String? location;
  final String? missingWord;
  final String? imageUrl;
  final String? emoji;
  final List<String>? distractorWords;
  final List<int>? pauseMarkers;
  final String? evidenceQuote;
  final List<String>? imageDescriptions;

  // D3 Additions (Games 16-20)
  final String? slowVersion;
  final int? emotionScale;
  final String? detailCategory;
  final String? literalMeaning;
  final String? locationContext;
  final List<String>? vocabularyWords;

  const ListeningQuest({
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
    this.audioUrl,
    super.textToSpeak,
    super.visualConfig,
    this.transcription,
    super.question,
    this.statement,
    this.shuffledSentences,
    this.correctOrder,
    this.prompt,
    super.explanation,
    this.textWithBlanks,
    this.audioOptions,
    this.transcript,
    this.targetEmotion,
    this.targetDetail,
    this.impliedMeaning,
    this.location,
    this.missingWord,
    this.imageUrl,
    this.emoji,
    this.distractorWords,
    this.pauseMarkers,
    this.evidenceQuote,
    this.imageDescriptions,
    this.slowVersion,
    this.emotionScale,
    this.detailCategory,
    this.literalMeaning,
    this.locationContext,
    this.vocabularyWords,
  });

  String? get audioTranscript => transcript ?? transcription ?? textToSpeak;

  @override
  List<Object?> get props => [
    ...super.props,
    audioUrl,
    transcription,
    statement,
    shuffledSentences,
    correctOrder,
    prompt,
    textWithBlanks,
    audioOptions,
    transcript,
    targetEmotion,
    targetDetail,
    impliedMeaning,
    location,
    missingWord,
    imageUrl,
    emoji,
    distractorWords,
    pauseMarkers,
    evidenceQuote,
    imageDescriptions,
    slowVersion,
    emotionScale,
    detailCategory,
    literalMeaning,
    locationContext,
    vocabularyWords,
  ];
}
