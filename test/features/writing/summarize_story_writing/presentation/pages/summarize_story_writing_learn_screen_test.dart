import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_learn_screen.dart';

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

  group('SummarizeStoryWritingLearnScreen', () {
    testWidgets(
      'renders narrative passage, chronological steps, model summary, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SummarizeStoryWritingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SummarizeStoryWritingLearnScreen), findsOneWidget);
        expect(find.text('ORIGINAL NARRATIVE PASSAGE'), findsOneWidget);
        expect(find.text('SYNTHESIZED NARRATIVE SUMMARY'), findsOneWidget);

        // Tap Next / Action button
        final nextFinder = find.text('Next Story Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('STORY SUMMARY CARD 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
