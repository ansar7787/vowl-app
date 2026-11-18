import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/pages/preposition_choice_mastery_screen.dart';

void main() {
  group('PrepositionChoiceMasteryScreen Type Alias', () {
    test('PrepositionChoiceMasteryScreen resolves identically to PrepositionChoiceScreen', () {
      expect(PrepositionChoiceMasteryScreen, equals(PrepositionChoiceScreen));
    });

    test('can instantiate PrepositionChoiceMasteryScreen with level and gameType', () {
      const screen = PrepositionChoiceMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<PrepositionChoiceScreen>());
    });
  });
}
