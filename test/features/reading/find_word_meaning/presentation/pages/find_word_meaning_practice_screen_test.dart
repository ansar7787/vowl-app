import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/pages/find_word_meaning_practice_screen.dart';

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

  group('FindWordMeaningPracticeScreen', () {
    testWidgets(
      'renders masked passage, selects correct meaning, reveals word and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const FindWordMeaningPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FindWordMeaningPracticeScreen), findsOneWidget);
        expect(find.text('Deduction Sandbox'), findsOneWidget);
        expect(find.text('INFERENCE CLUE'), findsOneWidget);
        expect(find.text('What does the masked word mean in this context?'), findsOneWidget);
        expect(find.text('feeling pleased or glad'), findsOneWidget);

        // Tap the correct meaning "feeling pleased or glad"
        final correctOptionFinder = find.text('feeling pleased or glad');
        await tester.ensureVisible(correctOptionFinder);
        await tester.tap(correctOptionFinder);
        await tester.pumpAndSettle();

        // Tap CHECK ANSWER
        final checkFinder = find.text('CHECK ANSWER');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        expect(find.text('EXCELLENT DEDUCTION!'), findsOneWidget);
        expect(find.text('happy'), findsWidgets);
        expect(find.text('NEXT QUESTION →'), findsOneWidget);

        // Tap NEXT QUESTION →
        final nextFinder = find.text('NEXT QUESTION →');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Quest 2 of'), findsOneWidget);
        expect(find.text('DEFINITION CLUE'), findsOneWidget);
      },
    );
  });
}
