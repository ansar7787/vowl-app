import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_practice_screen.dart';

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

  group('DescribeSituationWritingPracticeScreen', () {
    testWidgets(
      'renders Guided Description Gym, selects option, checks answer and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DescribeSituationWritingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DescribeSituationWritingPracticeScreen), findsOneWidget);
        expect(find.text('SITUATION PROMPT'), findsOneWidget);
        expect(
          find.text('SELECT THE OPTIMAL COHESIVE DESCRIPTION:'),
          findsOneWidget,
        );

        // Select the first option
        final firstOptionFinder = find.byType(GestureDetector).at(1);
        await tester.tap(firstOptionFinder);
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
                (w.data == 'Well Observed!' ||
                    w.data == 'Refine Your Description'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
