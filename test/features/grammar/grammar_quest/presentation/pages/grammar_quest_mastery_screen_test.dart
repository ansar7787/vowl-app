import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_mastery_screen.dart';

void main() {
  group('GrammarQuestMasteryScreen Type Alias', () {
    test('GrammarQuestMasteryScreen resolves identically to GrammarQuestScreen', () {
      expect(GrammarQuestMasteryScreen, equals(GrammarQuestScreen));
    });

    test('can instantiate GrammarQuestMasteryScreen with level and gameType', () {
      const screen = GrammarQuestMasteryScreen(level: 5);
      expect(screen.level, equals(5));
      expect(screen, isA<GrammarQuestScreen>());
    });
  });
}
