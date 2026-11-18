import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_mastery_screen.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_screen.dart';

void main() {
  group('FixTheSentenceMasteryScreen', () {
    test('is a type alias of FixTheSentenceScreen', () {
      const widget = FixTheSentenceMasteryScreen(level: 1);
      expect(widget, isA<FixTheSentenceScreen>());
      expect(widget.level, equals(1));
    });
  });
}
