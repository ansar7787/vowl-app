import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/connected_speech/presentation/pages/connected_speech_mastery_screen.dart';
import 'package:vowl/features/accent/connected_speech/presentation/pages/connected_speech_screen.dart';

void main() {
  group('ConnectedSpeechMasteryScreen', () {
    test('is a type alias of ConnectedSpeechScreen', () {
      const widget = ConnectedSpeechMasteryScreen(level: 1);
      expect(widget, isA<ConnectedSpeechScreen>());
      expect(widget.level, equals(1));
    });
  });
}
