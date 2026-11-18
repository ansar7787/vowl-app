import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_mastery_screen.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_screen.dart';

void main() {
  group('SentenceBuilderMasteryScreen', () {
    test('is a type alias of SentenceBuilderScreen', () {
      const widget = SentenceBuilderMasteryScreen(level: 1);
      expect(widget, isA<SentenceBuilderScreen>());
      expect(widget.level, equals(1));
    });
  });
}
