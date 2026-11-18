import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/pages/find_word_meaning_mastery_screen.dart';

void main() {
  group('FindWordMeaningMasteryScreen Type Alias', () {
    test('FindWordMeaningMasteryScreen resolves identically to FindWordMeaningScreen', () {
      expect(FindWordMeaningMasteryScreen, equals(FindWordMeaningScreen));
    });

    test('can instantiate FindWordMeaningMasteryScreen with level and gameType', () {
      const screen = FindWordMeaningMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<FindWordMeaningScreen>());
    });
  });
}
