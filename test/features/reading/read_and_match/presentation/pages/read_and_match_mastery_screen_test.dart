import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/read_and_match/presentation/pages/read_and_match_mastery_screen.dart';

void main() {
  group('ReadAndMatchMasteryScreen Type Alias', () {
    test('ReadAndMatchMasteryScreen resolves identically to ReadAndMatchScreen', () {
      expect(ReadAndMatchMasteryScreen, equals(ReadAndMatchScreen));
    });

    test('can instantiate ReadAndMatchMasteryScreen with level', () {
      const screen = ReadAndMatchMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ReadAndMatchScreen>());
    });
  });
}
