import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_mastery_screen.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_screen.dart';

void main() {
  group('VowelDistinctionMasteryScreen', () {
    test('is a type alias of VowelDistinctionScreen', () {
      const widget = VowelDistinctionMasteryScreen(level: 1);
      expect(widget, isA<VowelDistinctionScreen>());
      expect(widget.level, equals(1));
    });
  });
}
