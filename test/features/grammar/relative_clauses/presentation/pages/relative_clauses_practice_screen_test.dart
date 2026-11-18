import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/pages/relative_clauses_practice_screen.dart';

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

  group('RelativeClausesPracticeScreen', () {
    testWidgets(
      'renders question, selects correct option, reveals rationale, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const RelativeClausesPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(RelativeClausesPracticeScreen), findsOneWidget);
        expect(find.text('SYNTAX ARENA'), findsOneWidget);
        expect(
          find.text('who is standing by the door'),
          findsWidgets,
        );

        // Tap the correct relative clause option "who is standing by the door"
        final correctFinder = find.text('who is standing by the door').last;
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('SYNTAX SNAPPED'), findsOneWidget);
        expect(find.text('SYNTACTIC RATIONALE'), findsOneWidget);
        expect(find.text('NEXT EXERCISE'), findsOneWidget);

        // Tap NEXT EXERCISE
        final nextFinder = find.text('NEXT EXERCISE');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Exercise 2 of'), findsOneWidget);
      },
    );
  });
}
