import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/cloze_test/presentation/pages/cloze_test_learn_screen.dart';

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

  group('ClozeTestLearnScreen', () {
    testWidgets(
      'renders Collocation & Grammar Filter, sentence context, constraints, and advances card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ClozeTestLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ClozeTestLearnScreen), findsOneWidget);
        expect(find.text('COLLOCATION & GRAMMAR FILTER'), findsOneWidget);
        expect(find.text('SENTENCE CONTEXT WITH BLANK'), findsOneWidget);
        expect(find.text('TARGET COMPLETION'), findsOneWidget);
        expect(find.text('CANDIDATE WORD EVALUATION'), findsOneWidget);

        // Advance to next card
        final nextFinder = find.text('Next Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('CARD 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
