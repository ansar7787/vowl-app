import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/pages/sentence_correction_mastery_screen.dart';

void main() {
  group('SentenceCorrectionMasteryScreen Type Alias', () {
    test('SentenceCorrectionMasteryScreen resolves identically to SentenceCorrectionScreen', () {
      expect(SentenceCorrectionMasteryScreen, equals(SentenceCorrectionScreen));
    });

    test('can instantiate SentenceCorrectionMasteryScreen with level and gameType', () {
      const screen = SentenceCorrectionMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<SentenceCorrectionScreen>());
    });
  });
}
