/// Strongly-typed domain entity representing a semantic cluster group in Practice.
class TopicPracticeCluster {
  final String categoryName;
  final String emoji;
  final List<String> words;
  final String? explanation;
  final List<String> collocations;

  const TopicPracticeCluster({
    required this.categoryName,
    this.emoji = '✨',
    required this.words,
    this.explanation,
    this.collocations = const [],
  });

  factory TopicPracticeCluster.fromJson(Map<String, dynamic> json) {
    final rawWords = (json['words'] as List<dynamic>?) ?? [];
    final rawColls = (json['collocations'] as List<dynamic>?) ??
        (json['colls'] as List<dynamic>?) ?? [];
    return TopicPracticeCluster(
      categoryName: json['categoryName'] as String? ?? 'Category',
      emoji: json['emoji'] as String? ?? '✨',
      words: rawWords.map((e) => e.toString()).toList(),
      explanation: json['explanation'] as String?,
      collocations: rawColls.map((e) => e.toString()).toList(),
    );
  }
}

/// Strongly-typed domain entity representing a matrix board in Practice.
class TopicPracticeBoard {
  final int targetClusterSize;
  final List<String> tiles;
  final List<TopicPracticeCluster> clusters;
  final Map<String, String> clues;

  const TopicPracticeBoard({
    this.targetClusterSize = 3,
    required this.tiles,
    required this.clusters,
    this.clues = const {},
  });

  factory TopicPracticeBoard.fromJson(Map<String, dynamic> json) {
    final rawTiles = (json['tiles'] as List<dynamic>?) ?? [];
    final rawClusters = (json['clusters'] as List<dynamic>?) ?? [];
    final rawClues = json['clues'] as Map<String, dynamic>? ?? {};

    return TopicPracticeBoard(
      targetClusterSize: json['targetClusterSize'] as int? ?? 3,
      tiles: rawTiles.map((e) => e.toString()).toList(),
      clusters: rawClusters
          .map((c) => TopicPracticeCluster.fromJson(c as Map<String, dynamic>))
          .toList(),
      clues: rawClues.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

/// Strongly-typed domain entity for Practice Phase quests.
/// Completely decouples the UI from raw curriculum JSON dictionaries.
class TopicPracticeQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final List<TopicPracticeBoard> boards;

  const TopicPracticeQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.boards,
  });

  factory TopicPracticeQuest.fromJson(Map<String, dynamic> json) {
    final rawBoards = (json['boards'] as List<dynamic>?) ?? [];
    return TopicPracticeQuest(
      id: json['id'] as String? ?? 'VOC_TOPIC_PRACTICE',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Practice Words',
      boards: rawBoards
          .map((b) => TopicPracticeBoard.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  factory TopicPracticeQuest.fallback(int level) {
    return TopicPracticeQuest(
      id: 'VOC_TOPICVOCAB_L${level}_PRACTICE_FALLBACK',
      level: level,
      conceptTitle: 'Practice: Word Groups',
      boards: const [
        TopicPracticeBoard(
          targetClusterSize: 3,
          tiles: [
            'Anchor',
            'Pillar',
            'Bedrock',
            'Vortex',
            'Ripple',
            'Current',
          ],
          clusters: [
            TopicPracticeCluster(
              categoryName: 'Core Words',
              emoji: '🔹',
              words: ['Anchor', 'Pillar', 'Bedrock'],
              explanation: 'Fundamental vocabulary terms.',
              collocations: ['firm anchor', 'central pillar', 'solid bedrock'],
            ),
            TopicPracticeCluster(
              categoryName: 'Related Words',
              emoji: '🔸',
              words: ['Vortex', 'Ripple', 'Current'],
              explanation: 'Contextual terms in this topic.',
              collocations: ['polar vortex', 'ripple effect', 'ocean current'],
            ),
          ],
          clues: {
            'catAClue': 'Think of fundamental foundational words.',
            'catBClue': 'Think of dynamic contextual words.',
          },
        ),
      ],
    );
  }
}
