import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_mastery_screen.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_screen.dart';

void main() {
  group('SceneDescriptionSpeakingMasteryScreen', () {
    test('is a type alias of SceneDescriptionScreen', () {
      const widget = SceneDescriptionSpeakingMasteryScreen(level: 1);
      expect(widget, isA<SceneDescriptionScreen>());
      expect(widget.level, equals(1));
    });
  });
}
