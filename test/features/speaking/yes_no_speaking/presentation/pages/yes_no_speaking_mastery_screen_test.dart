import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_mastery_screen.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_screen.dart';

void main() {
  group('YesNoSpeakingMasteryScreen', () {
    test('is a type alias of YesNoSpeakingScreen', () {
      const widget = YesNoSpeakingMasteryScreen(level: 1);
      expect(widget, isA<YesNoSpeakingScreen>());
      expect(widget.level, equals(1));
    });
  });
}
