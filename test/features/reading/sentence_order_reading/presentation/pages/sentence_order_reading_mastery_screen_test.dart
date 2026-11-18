import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_mastery_screen.dart';

void main() {
  group('SentenceOrderReadingMasteryScreen Type Alias', () {
    test('SentenceOrderReadingMasteryScreen resolves identically to SentenceOrderReadingScreen', () {
      expect(SentenceOrderReadingMasteryScreen, equals(SentenceOrderReadingScreen));
    });

    test('can instantiate SentenceOrderReadingMasteryScreen with level', () {
      const screen = SentenceOrderReadingMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<SentenceOrderReadingScreen>());
    });
  });
}
