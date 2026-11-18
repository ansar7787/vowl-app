import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_mastery_screen.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_screen.dart';

void main() {
  group('EssayDraftingMasteryScreen', () {
    test('is a type alias of EssayDraftingScreen', () {
      const widget = EssayDraftingMasteryScreen(level: 1);
      expect(widget, isA<EssayDraftingScreen>());
      expect(widget.level, equals(1));
    });
  });
}
