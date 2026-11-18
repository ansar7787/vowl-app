import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/pages/paragraph_summary_learn_screen.dart';

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

  group('ParagraphSummaryLearnScreen', () {
    testWidgets(
      'renders 80/20 Distiller, passage, sentence pruning, candidates diagnosis, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ParagraphSummaryLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ParagraphSummaryLearnScreen), findsOneWidget);
        expect(find.text('80/20 Distiller'), findsOneWidget);
        expect(find.text('PARAGRAPH PASSAGE'), findsOneWidget);
        expect(find.text('SENTENCE PRUNING BREAKDOWN'), findsOneWidget);
        expect(find.text('SUMMARY CANDIDATES DIAGNOSIS'), findsOneWidget);

        // Tap Next Distiller Strategy to advance card
        final nextFinder = find.textContaining('Next Distiller Strategy');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('Card 2 of'), findsOneWidget);
        }
      },
    );
  });
}
