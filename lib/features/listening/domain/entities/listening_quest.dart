import 'package:voxai_quest/core/domain/entities/game_quest.dart';

class ListeningQuest extends GameQuest {
  final String? audioUrl;
  final String? transcription;
  final String? question;
  final String? statement;
  final List<String>? shuffledSentences;
  final List<int>? correctOrder;
  final String? prompt;
  final String? explanation;
  final String? textWithBlanks;
  final List<String>? audioOptions;
  final String? transcript;
  final String? targetEmotion;

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
    this.transcription,
    this.question,
    this.statement,
    this.shuffledSentences,
    this.correctOrder,
    this.prompt,
    this.explanation,
    this.textWithBlanks,
    this.audioOptions,
    this.transcript,
    this.targetEmotion,
    this.missingWord,
  });

  final String? missingWord;

  String? get audioTranscript => transcript ?? transcription ?? textToSpeak;
}
