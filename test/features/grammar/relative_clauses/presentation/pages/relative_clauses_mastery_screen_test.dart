import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/pages/relative_clauses_mastery_screen.dart';

void main() {
  group('RelativeClausesMasteryScreen Type Alias', () {
    test('RelativeClausesMasteryScreen resolves identically to RelativeClausesScreen', () {
      expect(RelativeClausesMasteryScreen, equals(RelativeClausesScreen));
    });

    test('can instantiate RelativeClausesMasteryScreen with level and gameType', () {
      const screen = RelativeClausesMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<RelativeClausesScreen>());
    });
  });
}
