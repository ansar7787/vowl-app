/// Strongly-typed domain entity representing a vocabulary word item
/// with its phonetic IPA, definition, and natural collocation.
class TopicWordDetail {
  final String word;
  final String ipa;
  final String definition;
  final String collocation;

  const TopicWordDetail({
    required this.word,
    this.ipa = '',
    this.definition = '',
    this.collocation = '',
  });

  factory TopicWordDetail.fromJson(Map<String, dynamic> json) {
    return TopicWordDetail(
      word: json['word'] as String? ?? '',
      ipa: json['ipa'] as String? ?? '',
      definition: json['def'] as String? ?? json['definition'] as String? ?? '',
      collocation: json['coll'] as String? ?? json['collocation'] as String? ?? '',
    );
  }
}

/// Strongly-typed domain entity representing a thematic category branch
/// containing related vocabulary words.
class TopicCategory {
  final String name;
  final String emoji;
  final String description;
  final List<TopicWordDetail> words;

  const TopicCategory({
    required this.name,
    this.emoji = '📌',
    this.description = '',
    required this.words,
  });

  factory TopicCategory.fromJson(Map<String, dynamic> json) {
    final rawWords = (json['words'] as List<dynamic>?) ?? [];
    return TopicCategory(
      name: json['name'] as String? ?? json['categoryName'] as String? ?? 'Topic',
      emoji: json['emoji'] as String? ?? '📌',
      description: json['desc'] as String? ?? json['description'] as String? ?? '',
      words: rawWords
          .map((w) => TopicWordDetail.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Strongly-typed domain entity for Learn Phase quests.
/// Completely decouples the UI from raw curriculum JSON dictionaries.
class TopicLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String topicEmoji;
  final List<TopicCategory> categories;
  final String? contrastInsight;

  const TopicLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    this.topicEmoji = '🏷️',
    required this.categories,
    this.contrastInsight,
  });

  factory TopicLearnQuest.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as List<dynamic>?) ?? [];
    return TopicLearnQuest(
      id: json['id'] as String? ?? 'VOC_TOPIC_LEARN',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Topic Words',
      topicEmoji: json['topicEmoji'] as String? ?? '🏷️',
      categories: rawCategories
          .map((c) => TopicCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
      contrastInsight: json['contrastInsight'] as String?,
    );
  }
}
