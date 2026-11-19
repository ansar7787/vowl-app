import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_mastery_screen.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_screen.dart';

void main() {
  group('EmotionRecognitionMasteryScreen', () {
    test('is a type alias of EmotionRecognitionScreen', () {
      const widget = EmotionRecognitionMasteryScreen(level: 1);
      expect(widget, isA<EmotionRecognitionScreen>());
      expect(widget.level, equals(1));
    });
  });
}
