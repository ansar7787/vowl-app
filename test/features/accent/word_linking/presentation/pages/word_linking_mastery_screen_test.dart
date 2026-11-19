import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/word_linking/presentation/pages/word_linking_mastery_screen.dart';
import 'package:vowl/features/accent/word_linking/presentation/pages/word_linking_screen.dart';

void main() {
  group('WordLinkingMasteryScreen', () {
    test('is a type alias of WordLinkingScreen', () {
      const widget = WordLinkingMasteryScreen(level: 1);
      expect(widget, isA<WordLinkingScreen>());
      expect(widget.level, equals(1));
    });
  });
}
