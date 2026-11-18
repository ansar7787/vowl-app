import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/conditionals/presentation/pages/conditionals_mastery_screen.dart';

void main() {
  group('ConditionalsMasteryScreen Type Alias', () {
    test('ConditionalsMasteryScreen resolves identically to ConditionalsScreen', () {
      expect(ConditionalsMasteryScreen, equals(ConditionalsScreen));
    });

    test('can instantiate ConditionalsMasteryScreen with level and gameType', () {
      const screen = ConditionalsMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ConditionalsScreen>());
    });
  });
}
