import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/pages/reading_speed_check_practice_screen.dart';

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

  group('ReadingSpeedCheckPracticeScreen', () {
    testWidgets(
      'renders Guided Pacing Gym, stops reading timer, selects comprehension option, and checks answer',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadingSpeedCheckPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadingSpeedCheckPracticeScreen), findsOneWidget);
        expect(find.text('Guided Pacing Gym'), findsOneWidget);
        expect(find.text('DONE READING'), findsOneWidget);

        // Tap DONE READING
        await tester.tap(find.text('DONE READING'));
        await tester.pumpAndSettle();

        // Comprehension question and options appear
        expect(find.text('Check Answer'), findsOneWidget);

        // Tap the first option letter 'A'
        final optionAFinder = find.text('A');
        expect(optionAFinder, findsOneWidget);
        await tester.tap(optionAFinder);
        await tester.pumpAndSettle();

        // Tap Check Answer
        final checkFinder = find.text('Check Answer');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback card appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data?.contains('SPEED & RETENTION VERIFIED!') == true ||
                    w.data?.contains('COMPREHENSION CHECK FAILED') == true),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
