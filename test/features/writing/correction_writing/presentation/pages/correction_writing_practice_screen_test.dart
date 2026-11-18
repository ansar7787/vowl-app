import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_practice_screen.dart';

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

  group('CorrectionWritingPracticeScreen', () {
    testWidgets(
      'renders flawed passage, selects replacement, checks and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const CorrectionWritingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CorrectionWritingPracticeScreen), findsOneWidget);
        expect(find.text('PASSAGE WITH BRACKETED FLAW'), findsOneWidget);
        expect(find.text('SELECT THE CORRECT REPLACEMENT WORD:'), findsOneWidget);

        // Select the first option
        final firstOptionFinder = find.byType(InkWell).first;
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Correction
        final checkFinder = find.text('Check Correction');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'PERFECT GRAMMATICAL REPAIR!' ||
                    widget.data == 'REPAIR FEEDBACK & REVISION'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
