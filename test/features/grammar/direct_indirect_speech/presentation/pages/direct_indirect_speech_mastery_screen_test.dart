import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/pages/direct_indirect_speech_mastery_screen.dart';

void main() {
  group('DirectIndirectSpeechMasteryScreen Type Alias', () {
    test('DirectIndirectSpeechMasteryScreen resolves identically to DirectIndirectSpeechScreen', () {
      expect(DirectIndirectSpeechMasteryScreen, equals(DirectIndirectSpeechScreen));
    });

    test('can instantiate DirectIndirectSpeechMasteryScreen with level and gameType', () {
      const screen = DirectIndirectSpeechMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<DirectIndirectSpeechScreen>());
    });
  });
}
