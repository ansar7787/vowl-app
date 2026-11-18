import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_practice_screen.dart';

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

  group('SummarizeStoryWritingPracticeScreen', () {
    testWidgets(
      'renders story passage, selects candidate summary, checks and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SummarizeStoryWritingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SummarizeStoryWritingPracticeScreen), findsOneWidget);
        expect(find.text('PASSAGE TO SUMMARIZE'), findsOneWidget);
        expect(find.text('CHOOSE THE BEST CHRONOLOGICAL SUMMARY:'), findsOneWidget);

        // Select the first option
        final firstOptionFinder = find.byType(InkWell).first;
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Summary
        final checkFinder = find.text('Check Summary');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'PERFECT NARRATIVE SUMMARY!' ||
                    widget.data == 'SUMMARY ANALYSIS & REVISION'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
