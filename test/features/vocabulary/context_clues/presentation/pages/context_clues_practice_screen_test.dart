import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_practice_screen.dart';

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

  group('ContextCluesPracticeScreen', () {
    testWidgets(
        'renders clue archetype choice exercise, validates option, and advances to active recall typing',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ContextCluesPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ContextCluesPracticeScreen), findsOneWidget);
      expect(find.text('CLUE ARCHETYPE IDENTIFICATION'), findsOneWidget);
      expect(
        find.textContaining("Which type of context clue unlocks the meaning of 'AMAZING'"),
        findsOneWidget,
      );

      // Select Definition Clue option
      final optionFinder = find.text('Definition Clue');
      await tester.ensureVisible(optionFinder);
      await tester.pumpAndSettle();
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Tap Check Answer
      final checkFinder = find.text('Check Answer');
      await tester.ensureVisible(checkFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkFinder);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('definition clue to clarify'),
        findsOneWidget,
      );
      expect(find.text('Next Exercise ➔'), findsOneWidget);

      // Tap Next Exercise
      final nextFinder = find.text('Next Exercise ➔');
      await tester.ensureVisible(nextFinder);
      await tester.pumpAndSettle();
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // Exercise 2: Active recall typing
      expect(find.text('ACTIVE RECALL MEANING DEDUCTION'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter typed meaning: 'wonderful'
      await tester.enterText(find.byType(TextField), 'wonderful');
      await tester.pumpAndSettle();

      // Check Answer
      final checkFinder2 = find.text('Check Answer');
      await tester.ensureVisible(checkFinder2);
      await tester.pumpAndSettle();
      await tester.tap(checkFinder2);
      await tester.pumpAndSettle();

      expect(
        find.text('Excellent deduction! You cracked the context clue.'),
        findsOneWidget,
      );
    });
  });
}
