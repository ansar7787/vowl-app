import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_mastery_screen.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_screen.dart';

void main() {
  group('SyllableStressMasteryScreen', () {
    test('is a type alias of SyllableStressScreen', () {
      const widget = SyllableStressMasteryScreen(level: 1);
      expect(widget, isA<SyllableStressScreen>());
      expect(widget.level, equals(1));
    });
  });
}
