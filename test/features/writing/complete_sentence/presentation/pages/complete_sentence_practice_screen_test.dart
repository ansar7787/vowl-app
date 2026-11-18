import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_practice_screen.dart';

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

  group('CompleteSentencePracticeScreen', () {
    testWidgets(
      'renders Thought Completer Gym, selects finishing clause, checks answer and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const CompleteSentencePracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CompleteSentencePracticeScreen), findsOneWidget);
        expect(find.text('THOUGHT COMPLETER'), findsOneWidget);
        expect(find.text('INCOMPLETE CLAUSE STEM'), findsOneWidget);
        expect(find.text('CANDIDATE PREDICATE COMPLETIONS'), findsOneWidget);

        // Select Option A
        final optionAFinder = find.text('A');
        expect(optionAFinder, findsOneWidget);
        await tester.tap(optionAFinder);
        await tester.pumpAndSettle();

        // Tap Check Clause Completion
        final checkFinder = find.text('Check Clause Completion');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'PERFECT CLAUSE COMPLETION!' ||
                    w.data == 'INCOMPLETE OR ILLOGICAL STRUCTURE'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
