import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_practice_screen.dart';

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

  group('DailyJournalPracticeScreen', () {
    testWidgets(
      'renders journal prompt, selects option, checks entry and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DailyJournalPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DailyJournalPracticeScreen), findsOneWidget);
        expect(find.text('JOURNAL PROMPT'), findsOneWidget);
        expect(find.text('SELECT THE BEST REFLECTIVE ENTRY:'), findsOneWidget);

        // Select the first option InkWell
        final firstOptionFinder = find.byType(InkWell).first;
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Entry
        final checkFinder = find.text('Check Entry');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'EXCELLENT JOURNAL ENTRY!' ||
                    widget.data == 'ENTRY FEEDBACK & ANALYSIS'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
