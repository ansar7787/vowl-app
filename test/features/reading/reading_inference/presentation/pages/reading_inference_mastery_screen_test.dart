import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_mastery_screen.dart';
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_screen.dart';

void main() {
  group('ReadingInferenceMasteryScreen Type Alias', () {
    test('ReadingInferenceMasteryScreen resolves identically to ReadingInferenceScreen', () {
      expect(ReadingInferenceMasteryScreen, equals(ReadingInferenceScreen));
    });

    test('can instantiate ReadingInferenceMasteryScreen with level', () {
      const screen = ReadingInferenceMasteryScreen(level: 3);
      expect(screen.level, equals(3));
      expect(screen, isA<ReadingInferenceScreen>());
    });
  });
}
