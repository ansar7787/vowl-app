import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_mastery_screen.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_screen.dart';

void main() {
  group('AudioMultipleChoiceMasteryScreen', () {
    test('is a type alias of AudioMultipleChoiceScreen', () {
      const widget = AudioMultipleChoiceMasteryScreen(level: 1);
      expect(widget, isA<AudioMultipleChoiceScreen>());
      expect(widget.level, equals(1));
    });
  });
}
