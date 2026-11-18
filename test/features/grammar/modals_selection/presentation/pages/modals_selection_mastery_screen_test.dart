import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/pages/modals_selection_mastery_screen.dart';

void main() {
  group('ModalsSelectionMasteryScreen Type Alias', () {
    test('ModalsSelectionMasteryScreen resolves identically to ModalsSelectionScreen', () {
      expect(ModalsSelectionMasteryScreen, equals(ModalsSelectionScreen));
    });

    test('can instantiate ModalsSelectionMasteryScreen with level and gameType', () {
      const screen = ModalsSelectionMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ModalsSelectionScreen>());
    });
  });
}
