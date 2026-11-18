import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/cloze_test/presentation/pages/cloze_test_mastery_screen.dart';
import 'package:vowl/features/reading/cloze_test/presentation/pages/cloze_test_screen.dart';

void main() {
  group('ClozeTestMasteryScreen Type Alias', () {
    test('ClozeTestMasteryScreen resolves identically to ClozeTestScreen', () {
      expect(ClozeTestMasteryScreen, equals(ClozeTestScreen));
    });

    test('can instantiate ClozeTestMasteryScreen with level', () {
      const screen = ClozeTestMasteryScreen(level: 4);
      expect(screen.level, equals(4));
      expect(screen, isA<ClozeTestScreen>());
    });
  });
}
