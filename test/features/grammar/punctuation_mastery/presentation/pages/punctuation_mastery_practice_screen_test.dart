import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_practice_screen.dart';

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

  group('PunctuationMasteryPracticeScreen', () {
    testWidgets(
      'renders instruction, sentence to punctuate, selects correct mark, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PunctuationMasteryPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PunctuationMasteryPracticeScreen), findsOneWidget);
        expect(find.text('SENTENCE TO PUNCTUATE'), findsOneWidget);
        expect(find.text('CHOOSE THE PUNCTUATION MARK:'), findsOneWidget);
        expect(find.text('.'), findsOneWidget);

        // Tap '.' (correct answer for level 1 quest 1)
        final correctFinder = find.text('.');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('PUNCTUATION CADENCE LOCKED!'), findsOneWidget);
        expect(find.text('PUNCTUATED RESULT'), findsOneWidget);
        expect(
          find.text('The library closes at nine tonight.'),
          findsOneWidget,
        );
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
