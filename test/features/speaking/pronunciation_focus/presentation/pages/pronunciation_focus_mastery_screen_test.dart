import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_mastery_screen.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_screen.dart';

void main() {
  group('PronunciationFocusMasteryScreen', () {
    test('is a type alias of PronunciationFocusScreen', () {
      const widget = PronunciationFocusMasteryScreen(level: 1);
      expect(widget, isA<PronunciationFocusScreen>());
      expect(widget.level, equals(1));
    });
  });
}
