import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_mastery_screen.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_screen.dart';

void main() {
  group('SpeakMissingWordMasteryScreen', () {
    test('is a type alias of SpeakMissingWordScreen', () {
      const widget = SpeakMissingWordMasteryScreen(level: 1);
      expect(widget, isA<SpeakMissingWordScreen>());
      expect(widget.level, equals(1));
    });
  });
}
