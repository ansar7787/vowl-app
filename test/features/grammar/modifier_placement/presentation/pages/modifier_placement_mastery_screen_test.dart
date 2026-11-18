import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/pages/modifier_placement_mastery_screen.dart';

void main() {
  group('ModifierPlacementMasteryScreen Type Alias', () {
    test('ModifierPlacementMasteryScreen resolves identically to ModifierPlacementScreen', () {
      expect(ModifierPlacementMasteryScreen, equals(ModifierPlacementScreen));
    });

    test('can instantiate ModifierPlacementMasteryScreen with level and gameType', () {
      const screen = ModifierPlacementMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ModifierPlacementScreen>());
    });
  });
}
