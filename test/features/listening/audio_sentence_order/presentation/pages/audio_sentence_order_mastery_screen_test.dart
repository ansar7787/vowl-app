import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_mastery_screen.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_screen.dart';

void main() {
  group('AudioSentenceOrderMasteryScreen', () {
    test('is a type alias of AudioSentenceOrderScreen', () {
      const widget = AudioSentenceOrderMasteryScreen(level: 1);
      expect(widget, isA<AudioSentenceOrderScreen>());
      expect(widget.level, equals(1));
    });
  });
}
