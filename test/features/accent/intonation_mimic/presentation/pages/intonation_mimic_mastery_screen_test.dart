import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_mastery_screen.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_screen.dart';

void main() {
  group('IntonationMimicMasteryScreen', () {
    test('is a type alias of IntonationMimicScreen', () {
      const widget = IntonationMimicMasteryScreen(level: 1);
      expect(widget, isA<IntonationMimicScreen>());
      expect(widget.level, equals(1));
    });
  });
}
