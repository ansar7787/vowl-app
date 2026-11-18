import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_writing_practice_screen.dart';

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

  group('ShortAnswerWritingPracticeScreen', () {
    testWidgets(
      'renders Structured Mini-Response Gym, selects option, checks answer and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ShortAnswerWritingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ShortAnswerWritingPracticeScreen), findsOneWidget);
        expect(find.text('SITUATION PROMPT'), findsOneWidget);
        expect(
          find.text('SELECT THE COMPLETE AND NATURAL REPLY:'),
          findsOneWidget,
        );

        // Select the first option
        final firstCandidateFinder = find.byType(GestureDetector).at(1);
        await tester.tap(firstCandidateFinder);
        await tester.pumpAndSettle();

        // Tap Check Answer
        final checkFinder = find.text('Check Answer');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'Well Answered!' ||
                    w.data == 'Incomplete Keywords'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
