import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_mastery_screen.dart';

void main() {
  group('PunctuationMasteryMasteryScreen Type Alias', () {
    test('PunctuationMasteryMasteryScreen resolves identically to PunctuationMasteryScreen', () {
      expect(PunctuationMasteryMasteryScreen, equals(PunctuationMasteryScreen));
    });

    test('can instantiate PunctuationMasteryMasteryScreen with level and gameType', () {
      const screen = PunctuationMasteryMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<PunctuationMasteryScreen>());
    });
  });
}
