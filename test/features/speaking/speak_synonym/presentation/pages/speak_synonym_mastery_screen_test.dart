import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_mastery_screen.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_screen.dart';

void main() {
  group('SpeakSynonymMasteryScreen', () {
    test('is a type alias of SpeakSynonymScreen', () {
      const widget = SpeakSynonymMasteryScreen(level: 1);
      expect(widget, isA<SpeakSynonymScreen>());
      expect(widget.level, equals(1));
    });
  });
}
