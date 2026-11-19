import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_mastery_screen.dart';
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart';

void main() {
  test('StoryBuilderMasteryScreen is an alias of StoryBuilderScreen', () {
    const screen = StoryBuilderMasteryScreen(level: 1);
    expect(screen, isA<StoryBuilderScreen>());
  });
}
