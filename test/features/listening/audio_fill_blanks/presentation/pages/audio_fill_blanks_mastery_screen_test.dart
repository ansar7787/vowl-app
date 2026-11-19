import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_mastery_screen.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_screen.dart';

void main() {
  group('AudioFillBlanksMasteryScreen', () {
    test('is a type alias of AudioFillBlanksScreen', () {
      const widget = AudioFillBlanksMasteryScreen(level: 1);
      expect(widget, isA<AudioFillBlanksScreen>());
      expect(widget.level, equals(1));
    });
  });
}
