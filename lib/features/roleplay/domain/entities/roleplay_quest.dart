import 'package:voxai_quest/core/domain/entities/game_quest.dart';

class RoleplayQuest extends GameQuest {
  final String? scenario;
  final String? persona;
  final String? prompt;
  final String? sampleAnswer;
  final dynamic nodes;
  final String? situation;
  final List<String>? keywords;
  final List<Map<String, String>>? conversationHistory;

  // Extra fields from various Roleplay games
  final String? lastLine;
  final String? dispatcherQuestion;
  final String? interviewerQuestion;

  const RoleplayQuest({
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
    this.scenario,
    this.persona,
    this.prompt,
    this.sampleAnswer,
    super.textToSpeak,
    this.nodes,
    this.situation,
    this.keywords,
    this.conversationHistory,
    this.lastLine,
    this.dispatcherQuestion,
    this.interviewerQuestion,
  });

  String? get roleName => persona;
  String? get explanation => scenario;
}
