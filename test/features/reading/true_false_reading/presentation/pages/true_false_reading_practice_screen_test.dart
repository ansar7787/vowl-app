import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/pages/true_false_reading_practice_screen.dart';

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

  group('TrueFalseReadingPracticeScreen', () {
    testWidgets(
      'enforces evidence selection, validates true/false evaluation, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const TrueFalseReadingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TrueFalseReadingPracticeScreen), findsOneWidget);
        expect(find.text('Evidence Highlighter'), findsOneWidget);
        expect(find.text('EVIDENCE GYM'), findsOneWidget);
        expect(find.text('TRUE'), findsOneWidget);
        expect(find.text('FALSE'), findsOneWidget);

        // 1. Tap CHECK ANSWER without selecting anything -> blocked warning
        final checkFinder = find.text('CHECK ANSWER');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Please choose TRUE or FALSE first'), findsOneWidget);

        // 2. Select TRUE
        final trueFinder = find.text('TRUE');
        await tester.ensureVisible(trueFinder);
        await tester.tap(trueFinder);
        await tester.pumpAndSettle();

        // 3. Tap CHECK ANSWER without selecting sentence -> blocked warning
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Submission blocked: Tap the sentence'), findsOneWidget);

        // 4. Select the supporting sentence in the passage
        final sentenceFinder = find.textContaining('She grows tomatoes and beans');
        await tester.ensureVisible(sentenceFinder);
        await tester.tap(sentenceFinder);
        await tester.pumpAndSettle();

        // 5. Tap CHECK ANSWER
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        expect(find.text('EVIDENCE VERIFIED!'), findsOneWidget);
        expect(find.text('NEXT QUESTION →'), findsOneWidget);

        // 6. Tap NEXT QUESTION →
        final nextFinder = find.text('NEXT QUESTION →');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Quest 2 of'), findsOneWidget);
      },
    );
  });
}
