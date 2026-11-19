import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_mastery_screen.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_screen.dart';

void main() {
  group('PitchPatternMatchMasteryScreen', () {
    test('is a type alias of PitchPatternMatchScreen', () {
      const widget = PitchPatternMatchMasteryScreen(level: 1);
      expect(widget, isA<PitchPatternMatchScreen>());
      expect(widget.level, equals(1));
    });
  });
}
