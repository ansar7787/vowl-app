import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';

void main() {
  group('WordSnapPuzzle Domain Model Tests', () {
    test('parses basic curriculum entry correctly', () {
      final map = {
        'id': 1,
        'word': 'ZEBRINE',
        'question': 'Pertaining to, or resembling, the zebra.',
      };

      final puzzle = WordSnapPuzzle.fromMap(map);

      expect(puzzle.id, equals(1));
      expect(puzzle.word, equals('ZEBRINE'));
      expect(puzzle.letterCount, equals(7));
      expect(puzzle.cleanDefinition, contains('Pertaining to, or resembling, the zebra'));
      expect(puzzle.playableWords.length, inInclusiveRange(4, 10));
      expect(puzzle.playableSentence, isNotEmpty);
      expect(puzzle.hintClue, startsWith('Starts with '));
    });

    test('strips author citations and bracketed lexicographical notes', () {
      final map = {
        'id': 2,
        'word': 'SEABEACH',
        'question': 'A beach lying along the sea. "The bleak seabeach." Longfellow.',
      };

      final puzzle = WordSnapPuzzle.fromMap(map);

      expect(puzzle.cleanDefinition, isNot(contains('"')));
      expect(puzzle.playableSentence, equals('A beach lying along the sea'));
      expect(puzzle.playableWords.length, equals(6));
    });

    test('handles archaic annotations like [Obs.] and [Scot.]', () {
      final map = {
        'id': 9,
        'word': 'GLAMOURIE',
        'question': 'Glamour. [Scot.]',
      };

      final puzzle = WordSnapPuzzle.fromMap(map);

      expect(puzzle.cleanDefinition, isNot(contains('[Scot.]')));
      expect(puzzle.playableWords.length, inInclusiveRange(4, 10));
    });

    test('handles long definitions with OCR spacing glitches without crashing', () {
      final map = {
        'id': 4,
        'word': 'GEOCRONITE',
        'question':
            'A lead-gray or grayish blue mineral with a metallic luster,consisting of sulphur, antimony, and lead, with a small proportion ofarsenic.',
      };

      final puzzle = WordSnapPuzzle.fromMap(map);

      expect(puzzle.cleanDefinition, contains('luster, consisting'));
      expect(puzzle.playableWords.length, inInclusiveRange(4, 10));
    });

    test('handles extremely short 1-word definition gracefully', () {
      final map = {
        'id': 43,
        'word': 'TAUTOLOGIC',
        'question': 'Tautological.',
      };

      final puzzle = WordSnapPuzzle.fromMap(map);

      expect(puzzle.playableWords.length, inInclusiveRange(4, 10));
      expect(puzzle.playableSentence.toLowerCase(), contains('tautological'));
    });

    test('verifies all 1460 items in split word_snap_curriculum.json parse with unified schema', () {
      final file = File('assets/curriculum/daily_challenges/word_snap_curriculum.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final list = data['items'] as List<dynamic>;

      expect(list.length, equals(1460));

      for (int i = 0; i < list.length; i++) {
        final item = Map<String, dynamic>.from(list[i] as Map);
        final puzzle = WordSnapPuzzle.fromMap(item);

        expect(puzzle.word, isNotEmpty);
        expect(puzzle.partOfSpeech, isNotEmpty);
        expect(['A1', 'A2', 'B1', 'B2', 'C1', 'C2'], contains(puzzle.cefrLevel));
        expect(puzzle.playableWords.length, inInclusiveRange(3, 10));
        expect(puzzle.playableSentence, isNotEmpty);
      }
    });
  });
}
