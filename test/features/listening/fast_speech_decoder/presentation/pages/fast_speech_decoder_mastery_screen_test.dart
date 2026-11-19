import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_mastery_screen.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_screen.dart';

void main() {
  group('FastSpeechDecoderMasteryScreen', () {
    test('is a type alias of FastSpeechDecoderScreen', () {
      const widget = FastSpeechDecoderMasteryScreen(level: 1);
      expect(widget, isA<FastSpeechDecoderScreen>());
      expect(widget.level, equals(1));
    });
  });
}
