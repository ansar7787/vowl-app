import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/pages/speak_opposite_mastery_screen.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/pages/speak_opposite_screen.dart';

void main() {
  group('SpeakOppositeMasteryScreen', () {
    test('is a type alias of SpeakOppositeScreen', () {
      const widget = SpeakOppositeMasteryScreen(level: 1);
      expect(widget, isA<SpeakOppositeScreen>());
      expect(widget.level, equals(1));
    });
  });
}
