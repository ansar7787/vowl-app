import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/pages/voice_swap_mastery_screen.dart';

void main() {
  group('VoiceSwapMasteryScreen Type Alias', () {
    test('VoiceSwapMasteryScreen resolves identically to VoiceSwapScreen', () {
      expect(VoiceSwapMasteryScreen, equals(VoiceSwapScreen));
    });

    test('can instantiate VoiceSwapMasteryScreen with level and gameType', () {
      const screen = VoiceSwapMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<VoiceSwapScreen>());
    });
  });
}
