import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/pages/true_false_reading_mastery_screen.dart';

void main() {
  group('TrueFalseReadingMasteryScreen Type Alias', () {
    test('TrueFalseReadingMasteryScreen resolves identically to TrueFalseReadingScreen', () {
      expect(TrueFalseReadingMasteryScreen, equals(TrueFalseReadingScreen));
    });

    test('can instantiate TrueFalseReadingMasteryScreen with level and gameType', () {
      const screen = TrueFalseReadingMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<TrueFalseReadingScreen>());
    });
  });
}
