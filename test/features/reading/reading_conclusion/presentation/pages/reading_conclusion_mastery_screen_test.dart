import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/pages/reading_conclusion_mastery_screen.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/pages/reading_conclusion_screen.dart';

void main() {
  group('ReadingConclusionMasteryScreen Type Alias', () {
    test('ReadingConclusionMasteryScreen resolves identically to ReadingConclusionScreen', () {
      expect(ReadingConclusionMasteryScreen, equals(ReadingConclusionScreen));
    });

    test('can instantiate ReadingConclusionMasteryScreen with level', () {
      const screen = ReadingConclusionMasteryScreen(level: 4);
      expect(screen.level, equals(4));
      expect(screen, isA<ReadingConclusionScreen>());
    });
  });
}
