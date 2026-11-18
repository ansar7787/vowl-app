import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/pages/word_reorder_mastery_screen.dart';

void main() {
  group('WordReorderMasteryScreen Type Alias', () {
    test('WordReorderMasteryScreen resolves identically to WordReorderScreen', () {
      expect(WordReorderMasteryScreen, equals(WordReorderScreen));
    });

    test('can instantiate WordReorderMasteryScreen with level and gameType', () {
      const screen = WordReorderMasteryScreen(level: 3);
      expect(screen.level, equals(3));
      expect(screen, isA<WordReorderScreen>());
    });
  });
}
