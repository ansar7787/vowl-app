import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/daily_challenges/handwriting/domain/models/handwriting_puzzle.dart';

void main() {
  group('HandwritingPuzzle Model Tests', () {
    test('parses foundational puzzle (level <= 50) correctly', () {
      final map = {
        'id': 'HW_L1_Q1',
        'level': 1,
        'instruction': 'Trace a standing line from top to bottom.',
        'question': '|',
        'correctAnswer': '|',
        'hint': 'Start at top dot and pull down.',
        'explanation': 'A vertical line goes from top to bottom.',
        'funFact': 'Ancient Sumerians used reeds to mark clay.',
      };

      final puzzle = HandwritingPuzzle.fromMap(map);

      expect(puzzle.id, equals('HW_L1_Q1'));
      expect(puzzle.level, equals(1));
      expect(puzzle.target, equals('|'));
      expect(puzzle.instruction, equals('Trace a standing line from top to bottom.'));
      expect(puzzle.difficultyLabel, equals('Foundational'));
      expect(puzzle.difficultyColor, equals(AppColors.emerald500));
      expect(puzzle.hasHint, isTrue);
      expect(puzzle.hasExplanation, isTrue);
      expect(puzzle.hasFunFact, isTrue);
    });

    test('parses intermediate puzzle (level 51-130) correctly', () {
      final map = {
        'id': 'HW_L60_Q1',
        'level': 60,
        'question': 'cat',
        'instruction': 'Write the word cat',
      };

      final puzzle = HandwritingPuzzle.fromMap(map);

      expect(puzzle.difficultyLabel, equals('Intermediate'));
      expect(puzzle.difficultyColor, equals(AppColors.amber500));
      expect(puzzle.target, equals('cat'));
    });

    test('parses mastery puzzle (level > 130) correctly', () {
      final map = {
        'id': 'HW_L150_Q1',
        'level': 150,
        'question': 'The quick brown fox',
        'instruction': 'Write the sentence',
      };

      final puzzle = HandwritingPuzzle.fromMap(map);

      expect(puzzle.difficultyLabel, equals('Mastery'));
      expect(puzzle.difficultyColor, equals(AppColors.rose500));
      expect(puzzle.target, equals('The quick brown fox'));
    });

    test('serializes toMap correctly', () {
      final map = {
        'id': 'HW_TEST',
        'level': 5,
        'instruction': 'Draw circle',
        'question': 'O',
        'correctAnswer': 'O',
        'hint': 'Round shape',
        'explanation': 'A circle has no corners',
        'funFact': 'Wheels are circles',
      };

      final puzzle = HandwritingPuzzle.fromMap(map);
      final serialized = puzzle.toMap();

      expect(serialized['id'], equals('HW_TEST'));
      expect(serialized['question'], equals('O'));
      expect(serialized['correctAnswer'], equals('O'));
    });
  });
}
