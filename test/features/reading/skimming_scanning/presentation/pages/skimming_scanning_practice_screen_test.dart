import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_practice_screen.dart';

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

  group('SkimmingScanningPracticeScreen', () {
    testWidgets(
      'renders Target Extraction Gym, selects target candidate, checks selection and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SkimmingScanningPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SkimmingScanningPracticeScreen), findsOneWidget);
        expect(find.text('PASSAGE TO SCAN'), findsOneWidget);
        expect(find.text('CHECK SELECTION'), findsOneWidget);

        // Select option B (Thursday) or option A
        final optionAFinder = find.text('A');
        expect(optionAFinder, findsOneWidget);
        await tester.tap(optionAFinder);
        await tester.pumpAndSettle();

        // Tap Check Selection
        final checkFinder = find.text('CHECK SELECTION');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'TARGET EXTRACTION SUCCESSFUL!' ||
                    w.data == 'TARGET MISMATCH'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
