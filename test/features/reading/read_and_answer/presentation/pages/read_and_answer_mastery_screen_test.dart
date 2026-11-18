import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_mastery_screen.dart';

void main() {
  group('ReadAndAnswerMasteryScreen Type Alias', () {
    test('ReadAndAnswerMasteryScreen resolves identically to ReadAndAnswerScreen', () {
      expect(ReadAndAnswerMasteryScreen, equals(ReadAndAnswerScreen));
    });

    test('can instantiate ReadAndAnswerMasteryScreen with level and gameType', () {
      const screen = ReadAndAnswerMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ReadAndAnswerScreen>());
    });
  });
}
