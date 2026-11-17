import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_practice_screen.dart';

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

  group('AcademicWordPracticeScreen', () {
    testWidgets(
        'renders passage choice, register contrast, typing gap-fill, and advances',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AcademicWordPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AcademicWordPracticeScreen), findsOneWidget);
      expect(find.text('EXERCISE 1 OF 3'), findsOneWidget);

      // Select 'ANALYZE'
      final optionFinder = find.text('ANALYZE');
      await tester.ensureVisible(optionFinder);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Check Answer
      final checkFinder = find.text('Check Answer');
      await tester.ensureVisible(checkFinder);
      await tester.tap(checkFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('carries precise scholarly weight'), findsOneWidget);
      expect(find.text('Next Exercise'), findsOneWidget);

      // Advance to Exercise 2 (Register Contrast)
      final nextFinder = find.text('Next Exercise');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(find.text('EXERCISE 2 OF 3'), findsOneWidget);

      // Select 'ANALYZE'
      final contrastOption = find.text('ANALYZE');
      await tester.ensureVisible(contrastOption);
      await tester.tap(contrastOption);
      await tester.pumpAndSettle();

      final check2Finder = find.text('Check Answer');
      await tester.ensureVisible(check2Finder);
      await tester.tap(check2Finder);
      await tester.pumpAndSettle();

      expect(find.textContaining('methodological precision'), findsOneWidget);

      // Advance to Exercise 3 (Typing)
      final next2Finder = find.text('Next Exercise');
      await tester.ensureVisible(next2Finder);
      await tester.tap(next2Finder);
      await tester.pumpAndSettle();

      expect(find.text('EXERCISE 3 OF 3'), findsOneWidget);
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.ensureVisible(textFieldFinder);
      await tester.enterText(textFieldFinder, 'ANALYZE');
      await tester.pumpAndSettle();

      final check3Finder = find.text('Check Answer');
      await tester.ensureVisible(check3Finder);
      await tester.tap(check3Finder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Spot on! You accurately recalled the scholarly term'), findsOneWidget);

      final finishFinder = find.text('Enter Mastery Arena 🏆');
      await tester.ensureVisible(finishFinder);
      expect(finishFinder, findsOneWidget);
    });
  });
}
