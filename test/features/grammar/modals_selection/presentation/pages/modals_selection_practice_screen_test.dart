import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/pages/modals_selection_practice_screen.dart';

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

  group('ModalsSelectionPracticeScreen', () {
    testWidgets(
      'renders question, selects correct modal "can", reveals tone insight, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ModalsSelectionPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ModalsSelectionPracticeScreen), findsOneWidget);
        expect(find.text('COMPLETE THE SENTENCE'), findsOneWidget);
        expect(
          find.text('My little brother ___ swim across the whole pool without stopping.'),
          findsOneWidget,
        );
        expect(find.text('can'), findsOneWidget);

        // Tap the correct modal option "can"
        final correctFinder = find.text('can');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('TONE PERFECT!'), findsOneWidget);
        expect(
          find.text('My little brother can swim across the whole pool without stopping.'),
          findsOneWidget,
        );
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
