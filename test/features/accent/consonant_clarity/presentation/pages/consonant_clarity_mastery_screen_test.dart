import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_mastery_screen.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_screen.dart';

void main() {
  group('ConsonantClarityMasteryScreen', () {
    test('is a type alias of ConsonantClarityScreen', () {
      const widget = ConsonantClarityMasteryScreen(level: 1);
      expect(widget, isA<ConsonantClarityScreen>());
      expect(widget.level, equals(1));
    });
  });
}
