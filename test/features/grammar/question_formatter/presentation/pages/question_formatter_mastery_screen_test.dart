import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/question_formatter/presentation/pages/question_formatter_mastery_screen.dart';

void main() {
  group('QuestionFormatterMasteryScreen Type Alias', () {
    test('QuestionFormatterMasteryScreen resolves identically to QuestionFormatterScreen', () {
      expect(QuestionFormatterMasteryScreen, equals(QuestionFormatterScreen));
    });

    test('can instantiate QuestionFormatterMasteryScreen with level and gameType', () {
      const screen = QuestionFormatterMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<QuestionFormatterScreen>());
    });
  });
}
