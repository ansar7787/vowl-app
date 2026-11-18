import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/pages/tense_mastery_mastery_screen.dart';

void main() {
  group('TenseMasteryMasteryScreen Type Alias', () {
    test('TenseMasteryMasteryScreen resolves identically to TenseMasteryScreen', () {
      expect(TenseMasteryMasteryScreen, equals(TenseMasteryScreen));
    });

    test('can instantiate TenseMasteryMasteryScreen with level and gameType', () {
      const screen = TenseMasteryMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<TenseMasteryScreen>());
    });
  });
}
