import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_mastery_screen.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_screen.dart';

void main() {
  group('CompleteSentenceMasteryScreen', () {
    test('is a type alias of CompleteSentenceScreen', () {
      const widget = CompleteSentenceMasteryScreen(level: 1);
      expect(widget, isA<CompleteSentenceScreen>());
      expect(widget.level, equals(1));
    });
  });
}
