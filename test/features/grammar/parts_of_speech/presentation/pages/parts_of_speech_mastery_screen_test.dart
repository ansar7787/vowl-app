import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_mastery_screen.dart';

void main() {
  group('PartsOfSpeechMasteryScreen Type Alias', () {
    test('PartsOfSpeechMasteryScreen resolves identically to PartsOfSpeechScreen', () {
      expect(PartsOfSpeechMasteryScreen, equals(PartsOfSpeechScreen));
    });

    test('can instantiate PartsOfSpeechMasteryScreen with level and gameType', () {
      const screen = PartsOfSpeechMasteryScreen(level: 5);
      expect(screen.level, equals(5));
      expect(screen, isA<PartsOfSpeechScreen>());
    });
  });
}
