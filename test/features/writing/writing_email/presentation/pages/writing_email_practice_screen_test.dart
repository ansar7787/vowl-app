import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_practice_screen.dart';

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

  group('WritingEmailPracticeScreen', () {
    testWidgets(
      'renders scenario, selects candidate email, checks and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const WritingEmailPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(WritingEmailPracticeScreen), findsOneWidget);
        expect(find.text('EMAIL SCENARIO'), findsOneWidget);
        expect(find.text('SELECT THE CORRECTLY ORDERED EMAIL:'), findsOneWidget);

        // Select the first option
        final firstOptionFinder = find.byType(InkWell).first;
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Email Assembly
        final checkFinder = find.text('Check Email Assembly');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'PERFECT EMAIL ASSEMBLY!' ||
                    widget.data == 'ASSEMBLY FEEDBACK & REVISION'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
