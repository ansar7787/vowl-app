import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_mastery_screen.dart';

void main() {
  group('FlashcardsMasteryScreen', () {
    test('is a type alias of FlashcardsScreen', () {
      const widget = FlashcardsMasteryScreen(level: 1);
      expect(widget, isA<FlashcardsScreen>());
      expect(widget.level, equals(1));
    });
  });
}
