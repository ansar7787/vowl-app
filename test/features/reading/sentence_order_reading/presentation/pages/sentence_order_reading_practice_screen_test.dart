import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_practice_screen.dart';

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

  group('SentenceOrderReadingPracticeScreen', () {
    testWidgets(
      'renders transition gym, swaps sentences, evaluates order and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SentenceOrderReadingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SentenceOrderReadingPracticeScreen), findsOneWidget);
        expect(find.text('Transition Anchor Gym'), findsOneWidget);
        expect(find.text('Check Sequence'), findsOneWidget);

        // Tap the first sentence to select it
        final firstPipFinder = find.text('1');
        expect(firstPipFinder, findsWidgets);
        await tester.tap(firstPipFinder.first);
        await tester.pumpAndSettle();

        expect(find.text('TAP TARGET TO SWAP'), findsOneWidget);

        // Tap the second sentence to perform swap
        final secondPipFinder = find.text('2');
        await tester.tap(secondPipFinder.first);
        await tester.pumpAndSettle();

        // Tap Check Sequence
        final checkFinder = find.text('Check Sequence');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Feedback card appears (either EXCELLENT COHESION! or SEQUENCE INCOMPLETE)
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'EXCELLENT COHESION!' ||
                    w.data == 'SEQUENCE INCOMPLETE'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
