import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_practice_screen.dart';

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

  group('IdiomsPracticeScreen', () {
    testWidgets(
        'renders scenario choice, validates answers, and advances through exercises',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const IdiomsPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(IdiomsPracticeScreen), findsOneWidget);
      expect(find.text('EXERCISE 1 OF 3'), findsOneWidget);

      // Select 'PIECE OF CAKE'
      final optionFinder = find.text('PIECE OF CAKE');
      await tester.ensureVisible(optionFinder);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Check Answer
      final checkFinder = find.text('Check Answer');
      await tester.ensureVisible(checkFinder);
      await tester.tap(checkFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('matches this exact figurative meaning'), findsOneWidget);
      expect(find.text('Next Exercise'), findsOneWidget);

      // Advance to Exercise 2
      final nextFinder = find.text('Next Exercise');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(find.text('EXERCISE 2 OF 3'), findsOneWidget);

      // Select 'Figuratively'
      final litFigOption = find.textContaining('Figuratively');
      await tester.ensureVisible(litFigOption);
      await tester.tap(litFigOption);
      await tester.pumpAndSettle();

      final check2Finder = find.text('Check Answer');
      await tester.ensureVisible(check2Finder);
      await tester.tap(check2Finder);
      await tester.pumpAndSettle();

      expect(find.textContaining('figurative meaning carries the real message'), findsOneWidget);

      // Advance to Exercise 3 (Typing)
      final next2Finder = find.text('Next Exercise');
      await tester.ensureVisible(next2Finder);
      await tester.tap(next2Finder);
      await tester.pumpAndSettle();

      expect(find.text('EXERCISE 3 OF 3'), findsOneWidget);
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.ensureVisible(textFieldFinder);
      await tester.enterText(textFieldFinder, 'PIECE OF CAKE');
      await tester.pumpAndSettle();

      final check3Finder = find.text('Check Answer');
      await tester.ensureVisible(check3Finder);
      await tester.tap(check3Finder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Spot on! You typed the correct expression'), findsOneWidget);

      final finishFinder = find.text('Enter Mastery Arena 🏆');
      await tester.ensureVisible(finishFinder);
      expect(finishFinder, findsOneWidget);
    });
  });
}
