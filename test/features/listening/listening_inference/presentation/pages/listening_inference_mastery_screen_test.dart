import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_mastery_screen.dart';
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_screen.dart';

void main() {
  group('ListeningInferenceMasteryScreen', () {
    test('is a type alias of ListeningInferenceScreen', () {
      const widget = ListeningInferenceMasteryScreen(level: 1);
      expect(widget, isA<ListeningInferenceScreen>());
      expect(widget.level, equals(1));
    });
  });
}
