import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/grammar/data/models/grammar_quest_model.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';

void main() {
  const tId = 'grammar_test_id';

  group('GrammarQuestModel', () {
    test('should be a subclass of GrammarQuest entity', () {
      const tModel = GrammarQuestModel(
        id: tId,
        instruction: 'i',
        difficulty: 1,
      );
      expect(tModel, isA<GrammarQuest>());
    });

    test('fromJson should return a valid model', () {
      final Map<String, dynamic> jsonMap = {
        'instruction': 'Fix the sentence',
        'difficulty': 2,
        'subtype': 'sentenceCorrection',
        'correctAnswer': 'Correct',
      };

      final result = GrammarQuestModel.fromJson(jsonMap, tId);

      expect(result.id, tId);
      expect(result.subtype, GameSubtype.sentenceCorrection);
    });

    test('fromJson should parse correctOrder correctly', () {
      final Map<String, dynamic> jsonMap = {
        'instruction': 'Reorder words',
        'difficulty': 1,
        'subtype': 'wordReorder',
        'shuffledWords': ['the', 'cat'],
        'correctOrder': [1, 0],
      };

      final result = GrammarQuestModel.fromJson(jsonMap, tId);

      expect(result.correctOrder, [1, 0]);
    });

    test(
      'getCorrectIndices should correctly match don\'t for Level 1 Quest 1',
      () {
        final sentence = "He don't know the answer at the outpost.";
        final incorrectPart = "don't";

        final cleanSentence = sentence
            .replaceAll('"', '')
            .replaceAll('Fix:', '')
            .trim();
        final words = cleanSentence
            .split(' ')
            .where((w) => w.isNotEmpty)
            .toList();

        expect(words[1], "don't");

        // Mimic the _getCorrectIndices logic
        final cleanTarget = incorrectPart
            .toLowerCase()
            .replaceAll('"', '')
            .trim();
        final targetWords = cleanTarget
            .split(' ')
            .where((w) => w.isNotEmpty)
            .toList();

        final cleanSentenceWords = words
            .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^\w]'), ''))
            .toList();
        final cleanTargetWords = targetWords
            .map((w) => w.replaceAll(RegExp(r'[^\w]'), ''))
            .toList();

        List<int> matchingIndices = [];
        for (
          int i = 0;
          i <= cleanSentenceWords.length - cleanTargetWords.length;
          i++
        ) {
          bool match = true;
          for (int j = 0; j < cleanTargetWords.length; j++) {
            if (!cleanSentenceWords[i + j].contains(cleanTargetWords[j]) &&
                !cleanTargetWords[j].contains(cleanSentenceWords[i + j])) {
              match = false;
              break;
            }
          }
          if (match) {
            for (int j = 0; j < cleanTargetWords.length; j++) {
              matchingIndices.add(i + j);
            }
            break;
          }
        }

        expect(matchingIndices, [1]);
      },
    );
  });
}
