import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/pages/paragraph_summary_mastery_screen.dart';

void main() {
  group('ParagraphSummaryMasteryScreen Type Alias', () {
    test('ParagraphSummaryMasteryScreen resolves identically to ParagraphSummaryScreen', () {
      expect(ParagraphSummaryMasteryScreen, equals(ParagraphSummaryScreen));
    });

    test('can instantiate ParagraphSummaryMasteryScreen with level', () {
      const screen = ParagraphSummaryMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ParagraphSummaryScreen>());
    });
  });
}
