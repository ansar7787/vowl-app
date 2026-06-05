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

  /// Safely parses any dynamic input into a List of strings, fallback to single string conversion or null.
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [value.toString()];
  }

  factory RoleplayQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.fromString(
      map['subtype'],
      fallback: GameSubtype.branchingDialogue,
    );

    Map<String, DialogueNode>? dialoguesMap;
    if (map['dialogues'] != null && map['dialogues'] is List) {
      dialoguesMap = {};
      final List<dynamic> dialoguesList = map['dialogues'];
      for (var nodeElement in dialoguesList) {
        if (nodeElement is! Map) continue;
        final nodeJson = Map<String, dynamic>.from(nodeElement);
        final String nodeId = nodeJson['id']?.toString() ?? '';
        if (nodeId.isEmpty) continue;
        
        List<DialogueChoice>? choices;
        if (nodeJson['choices'] != null && nodeJson['choices'] is List) {
          choices = (nodeJson['choices'] as List)
              .map((c) {
                if (c is Map) {
                  final choiceMap = Map<String, dynamic>.from(c);
                  return DialogueChoice(
                    text: choiceMap['text']?.toString() ?? '',
                    next: choiceMap['next']?.toString(),
                    score: (choiceMap['score'] as num?)?.toInt(),
                  );
                }
                return const DialogueChoice(text: '');
              })
              .where((c) => c.text.isNotEmpty)
              .toList();
        }

        final node = DialogueNode(
          id: nodeId,
          speaker: nodeJson['speaker']?.toString() ?? 'Unknown',
          text: nodeJson['text']?.toString() ?? '',
          end: nodeJson['end'] as bool? ?? false,
          emotion: nodeJson['emotion']?.toString(),
          choices: choices,
        );
        dialoguesMap[node.id] = node;
      }
    }

    return RoleplayQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction']?.toString() ?? 'Participate in the dialogue.',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      interactionType: InteractionType.fromString(
        map['interactionType'],
        fallback: InteractionType.choice,
      ),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (map['coinReward'] as num?)?.toInt() ?? 5,
      livesAllowed: (map['livesAllowed'] as num?)?.toInt() ?? 3,
      options: map['options'] != null
          ? _parseStringList(map['options'])
          : (map['choices'] != null ? _parseStringList(map['choices']) : null),
      correctAnswerIndex: (map['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: map['correctAnswer']?.toString(),
      hint: map['hint']?.toString(),
      visualConfig: map['visual_config'] != null 
          ? VisualConfig.fromJson(Map<String, dynamic>.from(map['visual_config'])) 
          : null,
      dialogues: dialoguesMap,
      situation: (map['situation'] ?? map['context'] ?? map['story'] ?? map['scenario'])?.toString(),
      keywords: _parseStringList(map['keywords']),
      scene: (map['scene'] ?? map['location'])?.toString(),
      lastLine: map['lastLine']?.toString(),
      dispatcherQuestion: map['dispatcherQuestion']?.toString(),
      interviewerQuestion: map['interviewerQuestion']?.toString(),
      persona: (map['persona'] ?? map['role'])?.toString(),
      prompt: (map['prompt'] ?? map['question'] ?? map['instruction'])?.toString(),
      sampleAnswer: (map['sampleAnswer'] ?? map['correctAnswer'])?.toString(),
      empathyScore: (map['empathyScore'] as num?)?.toDouble(),
      professionalismRating: (map['professionalismRating'] as num?)?.toInt(),
      symptoms: _parseStringList(map['symptoms']),
      itinerary: _parseStringList(map['itinerary']),
      explanation: map['explanation']?.toString(),
      shuffledWords: map['shuffledWords'] != null 
          ? _parseStringList(map['shuffledWords']) 
          : _parseStringList(map['keywords']),
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
      'shuffledWords': shuffledWords,
    };
  }
}
