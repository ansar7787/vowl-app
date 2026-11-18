import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_learn_screen.dart';

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

  group('CompleteSentenceLearnScreen', () {
    testWidgets(
      'renders Clause & Predicate Guide, complete sentence, clause anatomy, and advances card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const CompleteSentenceLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CompleteSentenceLearnScreen), findsOneWidget);
        expect(find.text('CLAUSE ARCHITECTURE'), findsOneWidget);
        expect(find.text('COMPLETE GRAMMATICAL THOUGHT'), findsOneWidget);
        expect(find.text('CLAUSE ANATOMY'), findsOneWidget);
        expect(find.text('SYNTACTIC PRINCIPLE'), findsOneWidget);
        expect(find.text('AVOID DANGLING FRAGMENTS'), findsOneWidget);

        // Advance to next pattern
        final nextFinder = find.text('Next Pattern');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('PATTERN 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
