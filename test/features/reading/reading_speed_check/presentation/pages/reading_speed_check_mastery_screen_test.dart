import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/pages/reading_speed_check_mastery_screen.dart';

void main() {
  group('ReadingSpeedCheckMasteryScreen Type Alias', () {
    test('ReadingSpeedCheckMasteryScreen resolves identically to ReadingSpeedCheckScreen', () {
      expect(ReadingSpeedCheckMasteryScreen, equals(ReadingSpeedCheckScreen));
    });

    test('can instantiate ReadingSpeedCheckMasteryScreen with level', () {
      const screen = ReadingSpeedCheckMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ReadingSpeedCheckScreen>());
    });
  });
}
