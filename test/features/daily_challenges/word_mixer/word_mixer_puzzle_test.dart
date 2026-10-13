import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';

void main() {
  group('WordMixerPuzzle Domain Model Tests', () {
    test('parses basic curriculum entry correctly', () {
      final map = {
        'id': 1,
        'word': 'SILLABUB',
        'hint':
            'A dish made by mixing wine or cider with milk, and thus forminga soft curd; also, sweetened cream, flavored with wine and beaten toa stiff froth. [Written also syllabub.]',
      };

      final puzzle = WordMixerPuzzle.fromMap(map);

      expect(puzzle.id, equals(1));
      expect(puzzle.word, equals('SILLABUB'));
      expect(puzzle.letterCount, equals(8));
      expect(puzzle.firstLetter, equals('S'));
      expect(puzzle.difficultyLabel, equals('Hard'));
      expect(puzzle.cleanHint, isNot(contains('[Written also syllabub.]')));
      expect(puzzle.cleanHint, contains('forminga soft curd'));
    });

    test('masks answer word in hint to prevent spoiler leakage', () {
      final map = {
        'id': 2,
        'word': 'TRENCHMORE',
        'hint':
            'A kind of lively dance of a rude, boisterous character. Also,music in triple time appropriate to the dance. [Obs.]All the windows in the town dance new trenchmore. Beau. & Fl.',
      };

      final puzzle = WordMixerPuzzle.fromMap(map);

      // Raw hint had "trenchmore", masked hint MUST NOT have "trenchmore"
      expect(puzzle.maskedHint.toLowerCase(), isNot(contains('trenchmore')));
      expect(puzzle.maskedHint, contains('______'));
    });

    test('verifies all 1460 items in split word_mixer_curriculum.json parse with unified schema', () {
      final file = File('assets/curriculum/daily_challenges/word_mixer_curriculum.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final list = data['items'] as List<dynamic>;

      expect(list.length, equals(1460));

      for (int i = 0; i < list.length; i++) {
        final item = Map<String, dynamic>.from(list[i] as Map);
        final puzzle = WordMixerPuzzle.fromMap(item);

        expect(puzzle.word, isNotEmpty);
        expect(puzzle.partOfSpeech, isNotEmpty);
        expect(['A1', 'A2', 'B1', 'B2', 'C1', 'C2'], contains(puzzle.cefrLevel));
        expect(puzzle.maskedHint, isNotEmpty);
        expect(puzzle.maskedHint.toLowerCase().contains(puzzle.word.toLowerCase()), isFalse);
      }
    });
  });
}
