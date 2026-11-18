import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/pages/article_insertion_practice_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    );
  }

  group('ArticleInsertionPracticeScreen', () {
    testWidgets(
      'renders instruction, article orbs, selects correct article, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ArticleInsertionPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ArticleInsertionPracticeScreen), findsOneWidget);
        expect(find.text('INSERT ARTICLE'), findsOneWidget);
        expect(find.text('CHOOSE THE NATURAL ARTICLE:'), findsOneWidget);
        expect(find.text('A'), findsOneWidget);
        expect(find.text('AN'), findsOneWidget);
        expect(find.text('THE'), findsOneWidget);

        // Tap 'A' (correct answer for level 1 quest 1)
        final correctFinder = find.text('A');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('ACOUSTIC HARMONY LOCKED IN!'), findsOneWidget);
        expect(find.text('COMPLETED SENTENCE'), findsOneWidget);
        expect(find.text('NEXT EXERCISE'), findsOneWidget);

        // Tap NEXT EXERCISE
        final nextFinder = find.text('NEXT EXERCISE');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Exercise 2 of'), findsOneWidget);
      },
    );
  });
}
