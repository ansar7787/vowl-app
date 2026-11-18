import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/pages/conjunctions_mastery_screen.dart';

void main() {
  group('ConjunctionsMasteryScreen Type Alias', () {
    test('ConjunctionsMasteryScreen resolves identically to ConjunctionsScreen', () {
      expect(ConjunctionsMasteryScreen, equals(ConjunctionsScreen));
    });

    test('can instantiate ConjunctionsMasteryScreen with level and gameType', () {
      const screen = ConjunctionsMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ConjunctionsScreen>());
    });
  });
}
