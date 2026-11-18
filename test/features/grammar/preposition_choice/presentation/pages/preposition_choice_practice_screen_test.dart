import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/pages/preposition_choice_practice_screen.dart';

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

  group('PrepositionChoicePracticeScreen', () {
    testWidgets(
      'renders question, selects correct preposition "in", reveals spatial harmony, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PrepositionChoicePracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PrepositionChoicePracticeScreen), findsOneWidget);
        expect(find.text('COMPLETE THE PREPOSITION'), findsOneWidget);
        expect(
          find.text('My notebook is ___ my backpack, along with my pens.'),
          findsOneWidget,
        );
        expect(find.text('in'), findsOneWidget);

        // Tap the correct preposition option "in"
        final correctFinder = find.text('in');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('SPATIAL HARMONY!'), findsOneWidget);
        expect(
          find.text('My notebook is in my backpack, along with my pens.'),
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
