import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_mastery_screen.dart';

void main() {
  group('PronounResolutionMasteryScreen Type Alias', () {
    test('PronounResolutionMasteryScreen resolves identically to PronounResolutionScreen', () {
      expect(PronounResolutionMasteryScreen, equals(PronounResolutionScreen));
    });

    test('can instantiate PronounResolutionMasteryScreen with level and gameType', () {
      const screen = PronounResolutionMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<PronounResolutionScreen>());
    });
  });
}
