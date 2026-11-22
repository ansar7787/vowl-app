import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_practice_quest.dart';

void main() {
  group('TopicPracticeQuest', () {
    test('fallback creates valid neutral cluster structure without hardcoded theme terms', () {
      final quest = TopicPracticeQuest.fallback(42);

      expect(quest.level, 42);
      expect(quest.boards, isNotEmpty);

      final board = quest.boards.first;
      expect(board.targetClusterSize, 3);
      expect(board.tiles.length, 6);
      expect(board.clusters.length, 2);

      // Verify emojis and category names are neutral
      expect(board.clusters[0].emoji, '🔹');
      expect(board.clusters[0].categoryName, 'Core Words');
      expect(board.clusters[1].emoji, '🔸');
      expect(board.clusters[1].categoryName, 'Related Words');

      // Verify words match cluster allocations
      final allWords = board.clusters.expand((c) => c.words).toSet();
      expect(board.tiles.toSet(), equals(allWords));
    });

    test('fromJson parses curriculum JSON payload correctly', () {
      final json = {
        'id': 'VOC_TOPIC_PRACTICE_L1',
        'level': 1,
        'conceptTitle': 'Weather & Climate',
        'boards': [
          {
            'targetClusterSize': 3,
            'tiles': ['Rain', 'Hail', 'Sleet', 'Breeze', 'Gale', 'Gust'],
            'clusters': [
              {
                'categoryName': 'Precipitation',
                'emoji': '🌧️',
                'words': ['Rain', 'Hail', 'Sleet'],
                'explanation': 'Types of water falling from the sky.',
                'collocations': ['heavy rain', 'hail storm', 'sleet and snow'],
              },
              {
                'categoryName': 'Wind',
                'emoji': '💨',
                'words': ['Breeze', 'Gale', 'Gust'],
                'explanation': 'Types of moving air.',
                'collocations': ['gentle breeze', 'gale force', 'strong gust'],
              },
            ],
            'clues': {
              'catAClue': 'Think of falling water.',
              'catBClue': 'Think of air and wind.',
            },
          },
        ],
      };

      final quest = TopicPracticeQuest.fromJson(json);
      expect(quest.id, 'VOC_TOPIC_PRACTICE_L1');
      expect(quest.level, 1);
      expect(quest.conceptTitle, 'Weather & Climate');
      expect(quest.boards.length, 1);
      expect(quest.boards.first.clusters.first.emoji, '🌧️');
    });
  });
}
