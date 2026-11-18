import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_practice_screen.dart';

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

  group('OpinionWritingPracticeScreen', () {
    testWidgets(
      'renders debate prompt, selects option, checks argument and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const OpinionWritingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(OpinionWritingPracticeScreen), findsOneWidget);
        expect(find.text('DEBATE PROMPT'), findsOneWidget);
        expect(find.text('SELECT THE SOUNDEST ARGUMENT:'), findsOneWidget);

        // Select the first option
        final firstCandidateFinder = find.byType(GestureDetector).at(1);
        await tester.tap(firstCandidateFinder);
        await tester.pumpAndSettle();

        // Tap Check Argument
        final checkFinder = find.text('Check Argument');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'Compelling Argument!' ||
                    widget.data == 'Flawed Reasoning Identified'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
