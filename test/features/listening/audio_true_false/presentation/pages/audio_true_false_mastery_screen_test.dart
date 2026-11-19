import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_mastery_screen.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_screen.dart';

void main() {
  group('AudioTrueFalseMasteryScreen', () {
    test('is a type alias of AudioTrueFalseScreen', () {
      const widget = AudioTrueFalseMasteryScreen(level: 1);
      expect(widget, isA<AudioTrueFalseScreen>());
      expect(widget.level, equals(1));
    });
  });
}
