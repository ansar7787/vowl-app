import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_practice_screen.dart';

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

  group('ReadingInferencePracticeScreen', () {
    testWidgets(
      'renders Subtext Detector Gym, selects option, checks answer and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadingInferencePracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadingInferencePracticeScreen), findsOneWidget);
        expect(find.text('Subtext Detector Gym'), findsOneWidget);
        expect(find.text('Check Subtext'), findsOneWidget);

        // Option A is present
        final optionAFinder = find.text('A');
        expect(optionAFinder, findsOneWidget);
        await tester.tap(optionAFinder);
        await tester.pumpAndSettle();

        // Tap Check Subtext button
        final checkFinder = find.text('Check Subtext');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears (either SUBTEXT DETECTED! or RADAR DEFLECTION)
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'SUBTEXT DETECTED!' ||
                    w.data == 'RADAR DEFLECTION'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
