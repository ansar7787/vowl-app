import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/question_formatter/presentation/pages/question_formatter_practice_screen.dart';

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

  group('QuestionFormatterPracticeScreen', () {
    testWidgets(
      'renders instruction, statement to invert, selects correct question format, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const QuestionFormatterPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(QuestionFormatterPracticeScreen), findsOneWidget);
        expect(find.text('STATEMENT TO INVERT'), findsOneWidget);
        expect(
          find.text('SELECT THE CORRECT QUESTION FORMAT:'),
          findsOneWidget,
        );
        expect(find.text('Am I ready for the meeting?'), findsOneWidget);

        // Tap 'Am I ready for the meeting?' (correct answer for level 1 quest 1)
        final correctFinder = find.text('Am I ready for the meeting?');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('INVERSION HARMONY ACHIEVED!'), findsOneWidget);
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
