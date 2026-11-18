import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_mastery_screen.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_screen.dart';

void main() {
  group('SkimmingScanningMasteryScreen Type Alias', () {
    test('SkimmingScanningMasteryScreen resolves identically to SkimmingScanningScreen', () {
      expect(SkimmingScanningMasteryScreen, equals(SkimmingScanningScreen));
    });

    test('can instantiate SkimmingScanningMasteryScreen with level', () {
      const screen = SkimmingScanningMasteryScreen(level: 4);
      expect(screen.level, equals(4));
      expect(screen, isA<SkimmingScanningScreen>());
    });
  });
}
