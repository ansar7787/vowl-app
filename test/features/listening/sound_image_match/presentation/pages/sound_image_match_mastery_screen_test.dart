import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_mastery_screen.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_screen.dart';

void main() {
  group('SoundImageMatchMasteryScreen', () {
    test('is a type alias of SoundImageMatchScreen', () {
      const widget = SoundImageMatchMasteryScreen(level: 1);
      expect(widget, isA<SoundImageMatchScreen>());
      expect(widget.level, equals(1));
    });
  });
}
