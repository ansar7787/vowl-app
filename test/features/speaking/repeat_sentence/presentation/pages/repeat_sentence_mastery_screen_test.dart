import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_mastery_screen.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_screen.dart';

void main() {
  group('RepeatSentenceMasteryScreen', () {
    test('is a type alias of RepeatSentenceScreen', () {
      const widget = RepeatSentenceMasteryScreen(level: 1);
      expect(widget, isA<RepeatSentenceScreen>());
      expect(widget.level, equals(1));
    });
  });
}
