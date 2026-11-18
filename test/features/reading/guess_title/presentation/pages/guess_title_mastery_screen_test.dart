import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/guess_title/presentation/pages/guess_title_mastery_screen.dart';

void main() {
  group('GuessTitleMasteryScreen Type Alias', () {
    test('GuessTitleMasteryScreen resolves identically to GuessTitleScreen', () {
      expect(GuessTitleMasteryScreen, equals(GuessTitleScreen));
    });

    test('can instantiate GuessTitleMasteryScreen with level', () {
      const screen = GuessTitleMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<GuessTitleScreen>());
    });
  });
}
