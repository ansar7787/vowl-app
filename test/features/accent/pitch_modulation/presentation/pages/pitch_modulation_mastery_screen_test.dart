import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/pages/pitch_modulation_mastery_screen.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/pages/pitch_modulation_screen.dart';

void main() {
  group('PitchModulationMasteryScreen', () {
    test('is a type alias of PitchModulationScreen', () {
      const widget = PitchModulationMasteryScreen(level: 1);
      expect(widget, isA<PitchModulationScreen>());
      expect(widget.level, equals(1));
    });
  });
}
