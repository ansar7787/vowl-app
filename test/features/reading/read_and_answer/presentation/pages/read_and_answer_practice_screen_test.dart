import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_practice_screen.dart';

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

  group('ReadAndAnswerPracticeScreen', () {
    testWidgets(
      'renders passage, selects correct option, checks answer and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadAndAnswerPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadAndAnswerPracticeScreen), findsOneWidget);
        expect(find.text('At what time does the library close on Saturday?'), findsOneWidget);
        expect(find.text('At noon'), findsWidgets);

        // Tap the correct option "At noon"
        final correctOptionFinder = find.text('At noon').last;
        await tester.ensureVisible(correctOptionFinder);
        await tester.tap(correctOptionFinder);
        await tester.pumpAndSettle();

        expect(find.text('CHECK ANSWER'), findsOneWidget);

        // Tap CHECK ANSWER
        final checkFinder = find.text('CHECK ANSWER');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        expect(find.text('EVIDENCE VERIFIED!'), findsOneWidget);
        expect(find.text('NEXT PASSAGE CHECK →'), findsOneWidget);

        // Tap NEXT PASSAGE CHECK →
        final nextFinder = find.text('NEXT PASSAGE CHECK →');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Question 2 of'), findsOneWidget);
      },
    );
  });
}
