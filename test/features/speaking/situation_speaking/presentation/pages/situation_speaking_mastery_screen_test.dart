import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/pages/situation_speaking_mastery_screen.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/pages/situation_speaking_screen.dart';

void main() {
  group('SituationSpeakingMasteryScreen', () {
    test('is a type alias of SituationSpeakingScreen', () {
      const widget = SituationSpeakingMasteryScreen(level: 1);
      expect(widget, isA<SituationSpeakingScreen>());
      expect(widget.level, equals(1));
    });
  });
}
