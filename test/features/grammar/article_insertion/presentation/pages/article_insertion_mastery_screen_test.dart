import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/pages/article_insertion_mastery_screen.dart';

void main() {
  group('ArticleInsertionMasteryScreen Type Alias', () {
    test('ArticleInsertionMasteryScreen resolves identically to ArticleInsertionScreen', () {
      expect(ArticleInsertionMasteryScreen, equals(ArticleInsertionScreen));
    });

    test('can instantiate ArticleInsertionMasteryScreen with level and gameType', () {
      const screen = ArticleInsertionMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ArticleInsertionScreen>());
    });
  });
}
