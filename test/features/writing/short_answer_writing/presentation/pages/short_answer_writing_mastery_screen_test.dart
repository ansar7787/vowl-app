import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_writing_mastery_screen.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_screen.dart';

void main() {
  group('ShortAnswerMasteryScreen', () {
    test('is a type alias of ShortAnswerScreen', () {
      const widget = ShortAnswerMasteryScreen(level: 1);
      expect(widget, isA<ShortAnswerScreen>());
      expect(widget.level, equals(1));
    });
  });
}

