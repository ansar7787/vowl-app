import '../../domain/entities/roleplay_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class RoleplayQuestModel extends RoleplayQuest {
  const RoleplayQuestModel({
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
    super.nodes,
    super.situation,
    super.keywords,
    super.scenario,
    super.lastLine,
    super.dispatcherQuestion,
    super.interviewerQuestion,
    super.persona,
    super.prompt,
    super.sampleAnswer,
  });

  factory RoleplayQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.branchingDialogue,
    );
    return RoleplayQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Participate in the dialogue.',
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
      correctAnswerIndex: map['correctAnswerIndex'],
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      nodes: map['nodes'],
      situation: map['situation'],
      keywords: map['keywords'] != null
          ? List<String>.from(map['keywords'])
          : null,
      scenario: map['scenario'],
      lastLine: map['lastLine'],
      dispatcherQuestion: map['dispatcherQuestion'],
      interviewerQuestion: map['interviewerQuestion'],
      persona: map['persona'],
      prompt: map['prompt'],
      sampleAnswer: map['sampleAnswer'],
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
      'nodes': nodes,
      'situation': situation,
      'keywords': keywords,
      'scenario': scenario,
      'lastLine': lastLine,
      'dispatcherQuestion': dispatcherQuestion,
      'interviewerQuestion': interviewerQuestion,
      'persona': persona,
      'prompt': prompt,
      'sampleAnswer': sampleAnswer,
    };
  }
}
