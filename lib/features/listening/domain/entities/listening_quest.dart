import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity representing an auditory comprehension challenge.
class ListeningQuest extends GameQuest {
  /// Verbatim transcription of the acoustic audio stream.
  final String? transcription;

  /// True/false statement evaluated against the audio passage.
  final String? statement;

  /// Sentence segments to be reordered chronologically.
  final List<String>? shuffledSentences;

  /// Correct permutation sequence indices for sentence segments.
  final List<int>? correctOrder;

  /// Contextual listening prompt or scenario premise.
  final String? prompt;

  /// Passage text featuring missing blanks.
  final String? textWithBlanks;

  /// Candidate audio choices or spoken options.
  final List<String>? audioOptions;

  /// Full conversational script transcript.
  final String? transcript;

  /// Targeted affective tone or emotional state.
  final String? targetEmotion;

  /// Specific factual detail queried in the question.
  final String? targetDetail;

  /// Inferred pragmatic meaning behind the utterance.
  final String? impliedMeaning;

  /// Environmental setting or ambient location.
  final String? location;

  /// Lexical item omitted in audio fill-in-the-blank.
  final String? missingWord;

  /// Illustrative emoji glyph.
  final String? emoji;

  /// Incorrect lexical distractors in audio fill exercises.
  final List<String>? distractorWords;

  /// Millisecond timestamp markers indicating natural pauses.
  final List<int>? pauseMarkers;

  /// Excerpt from audio proving the correct comprehension answer.
  final String? evidenceQuote;

  /// Associated emoji icons for candidate option tiles.
  final List<String>? optionEmojis;

  // D3 Additions (Games 16-20)
  /// Integer intensity level of the target emotion.
  final int? emotionScale;

  /// Classification of the queried detail (e.g., time, location).
  final String? detailCategory;

  /// Surface denotation vs figurative meaning.
  final String? literalMeaning;

  /// Environmental ambient context description.
  final String? locationContext;

  /// Essential lexical tokens embedded in the audio passage.
  final List<String>? vocabularyWords;

  /// Creates a [ListeningQuest] entity.
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
    this.emoji,
    this.distractorWords,
    this.pauseMarkers,
    this.evidenceQuote,
    this.optionEmojis,
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
    emoji,
    distractorWords,
    pauseMarkers,
    evidenceQuote,
    optionEmojis,
    emotionScale,
    detailCategory,
    literalMeaning,
    locationContext,
    vocabularyWords,
  ];
}
