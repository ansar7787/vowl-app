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
    super.visualConfig,
    super.dialogues,
    super.situation,
    super.keywords,
    super.scene,
    super.lastLine,
    super.dispatcherQuestion,
    super.interviewerQuestion,
    super.persona,
    super.prompt,
    super.sampleAnswer,
    super.empathyScore,
    super.professionalismRating,
    super.symptoms,
    super.itinerary,
    super.explanation,
    super.shuffledWords,
  });

  factory RoleplayQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.branchingDialogue,
    );

    Map<String, DialogueNode>? dialoguesMap;
    if (map['dialogues'] != null) {
      dialoguesMap = {};
      final List<dynamic> dialoguesList = map['dialogues'];
      for (var nodeJson in dialoguesList) {
        final node = DialogueNode(
          id: nodeJson['id'],
          speaker: nodeJson['speaker'] ?? 'Unknown',
          text: nodeJson['text'] ?? '',
          end: nodeJson['end'] ?? false,
          emotion: nodeJson['emotion'],
          choices: nodeJson['choices'] != null
              ? (nodeJson['choices'] as List)
                    .map(
                      (c) => DialogueChoice(
                        text: c['text'] ?? '',
                        next: c['next'],
                        score: c['score'],
                      ),
                    )
                    .toList()
              : null,
        );
        dialoguesMap[node.id] = node;
      }
    }

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
      livesAllowed: map['livesAllowed'] ?? 3,
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : (map['choices'] != null ? List<String>.from(map['choices']) : null),
      correctAnswerIndex: map['correctAnswerIndex'],
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      visualConfig: map['visual_config'] != null ? VisualConfig.fromJson(Map<String, dynamic>.from(map['visual_config'])) : null,
      dialogues: dialoguesMap,
      situation: map['situation'] ?? map['context'] ?? map['story'] ?? map['scenario'],
      keywords: map['keywords'] != null
          ? List<String>.from(map['keywords'])
          : null,
      scene: map['scene'] ?? map['location'],
      lastLine: map['lastLine'],
      dispatcherQuestion: map['dispatcherQuestion'],
      interviewerQuestion: map['interviewerQuestion'],
      persona: map['persona'] ?? map['role'],
      prompt: map['prompt'] ?? map['question'] ?? map['instruction'],
      sampleAnswer: map['sampleAnswer'] ?? map['correctAnswer'],
      empathyScore: (map['empathyScore'] as num?)?.toDouble(),
      professionalismRating: map['professionalismRating'],
      symptoms: map['symptoms'] != null ? List<String>.from(map['symptoms']) : null,
      itinerary: map['itinerary'] != null ? List<String>.from(map['itinerary']) : null,
      explanation: map['explanation'],
      shuffledWords: map['shuffledWords'] != null ? List<String>.from(map['shuffledWords']) : (map['keywords'] != null ? List<String>.from(map['keywords']) : null),
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
      'dialogues': dialogues?.values
          .map(
            (node) => {
              'id': node.id,
              'speaker': node.speaker,
              'text': node.text,
              'end': node.end,
              'emotion': node.emotion,
              'choices': node.choices
                  ?.map(
                    (c) => {'text': c.text, 'next': c.next, 'score': c.score},
                  )
                  .toList(),
            },
          )
          .toList(),
      'situation': situation,
      'keywords': keywords,
      'scene': scene,
      'lastLine': lastLine,
      'dispatcherQuestion': dispatcherQuestion,
      'interviewerQuestion': interviewerQuestion,
      'persona': persona,
      'prompt': prompt,
      'sampleAnswer': sampleAnswer,
      'empathyScore': empathyScore,
      'professionalismRating': professionalismRating,
      'symptoms': symptoms,
      'itinerary': itinerary,
      'explanation': explanation,
    };
  }
}

