import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_mastery_screen.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_screen.dart';

void main() {
  group('SummarizeStoryWritingMasteryScreen', () {
    test('is a type alias of SummarizeStoryWritingScreen', () {
      const widget = SummarizeStoryWritingMasteryScreen(level: 1);
      expect(widget, isA<SummarizeStoryWritingScreen>());
      expect(widget.level, equals(1));
    });
  });
}
