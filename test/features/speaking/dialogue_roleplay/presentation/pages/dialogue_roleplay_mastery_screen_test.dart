import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_mastery_screen.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart';

void main() {
  group('DialogueRoleplayMasteryScreen', () {
    test('is a type alias of DialogueRoleplayScreen', () {
      const widget = DialogueRoleplayMasteryScreen(level: 1);
      expect(widget, isA<DialogueRoleplayScreen>());
      expect(widget.level, equals(1));
    });
  });
}
