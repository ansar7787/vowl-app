import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_mastery_screen.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_screen.dart';

void main() {
  group('OpinionWritingMasteryScreen', () {
    test('is a type alias of OpinionWritingScreen', () {
      const widget = OpinionWritingMasteryScreen(level: 1);
      expect(widget, isA<OpinionWritingScreen>());
      expect(widget.level, equals(1));
    });
  });
}
