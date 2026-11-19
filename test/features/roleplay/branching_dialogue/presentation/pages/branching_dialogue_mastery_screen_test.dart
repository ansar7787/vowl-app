import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_mastery_screen.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_screen.dart';

void main() {
  group('BranchingDialogueMasteryScreen', () {
    test('is a type alias of BranchingDialogueScreen', () {
      const widget = BranchingDialogueMasteryScreen(level: 1);
      expect(widget, isA<BranchingDialogueScreen>());
      expect(widget.level, equals(1));
    });
  });
}
