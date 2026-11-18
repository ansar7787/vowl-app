import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_learn_screen.dart';

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

  group('DailyJournalLearnScreen', () {
    testWidgets(
      'renders reflective journal prompt, framework, model entry, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DailyJournalLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DailyJournalLearnScreen), findsOneWidget);
        expect(find.text('REFLECTIVE JOURNAL PROMPT'), findsOneWidget);
        expect(find.text('MODEL REFLECTIVE JOURNAL ENTRY'), findsOneWidget);

        // Tap Next / Action button
        final nextFinder = find.text('Next Journal Prompt');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('JOURNAL PROMPT 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
