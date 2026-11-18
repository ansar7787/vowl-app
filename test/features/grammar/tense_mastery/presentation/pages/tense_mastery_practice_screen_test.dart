import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/pages/tense_mastery_practice_screen.dart';

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

  group('TenseMasteryPracticeScreen', () {
    testWidgets(
      'renders target sentence, handles timeline selection, reveals feedback and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const TenseMasteryPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TenseMasteryPracticeScreen), findsOneWidget);
        expect(find.text('TARGET SENTENCE'), findsOneWidget);
        expect(find.text('WHERE DOES THIS OCCUR?'), findsOneWidget);
        expect(find.text('PAST'), findsOneWidget);
        expect(find.text('PRESENT'), findsOneWidget);
        expect(find.text('FUTURE'), findsOneWidget);

        // Tap 'PAST' (correct for level 1 quest 1)
        final pastFinder = find.text('PAST');
        await tester.ensureVisible(pastFinder);
        await tester.tap(pastFinder);
        await tester.pumpAndSettle();

        expect(find.text('TIMELINE LOCKED IN!'), findsOneWidget);
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
