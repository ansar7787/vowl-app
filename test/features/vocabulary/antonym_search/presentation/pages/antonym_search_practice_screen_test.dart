import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_practice_screen.dart';

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

  group('AntonymSearchPracticeScreen', () {
    testWidgets(
        'renders contrast choice exercise, validates option, and advances to typing exercise',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AntonymSearchPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AntonymSearchPracticeScreen), findsOneWidget);
      expect(find.text('CONTRAST SELECTION'), findsOneWidget);
      expect(
          find.textContaining('I am standing right here, but my brother is'),
          findsOneWidget);

      // Select correct option (index 0)
      final optionFinder =
          find.textContaining('I am standing right here, but my brother is');
      await tester.ensureVisible(optionFinder);
      await tester.pumpAndSettle();
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Submit answer
      final checkFinder = find.text('Check Answer');
      await tester.ensureVisible(checkFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Perfect!'), findsOneWidget);
      expect(find.text('Next Exercise ➔'), findsOneWidget);

      // Advance to exercise 2 (typing active recall)
      final nextFinder = find.text('Next Exercise ➔');
      await tester.ensureVisible(nextFinder);
      await tester.pumpAndSettle();
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE RECALL TYPING'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter typed antonym
      await tester.enterText(find.byType(TextField), 'there');
      await tester.pumpAndSettle();

      // Check typed answer
      final checkFinder2 = find.text('Check Answer');
      await tester.ensureVisible(checkFinder2);
      await tester.pumpAndSettle();
      await tester.tap(checkFinder2);
      await tester.pumpAndSettle();

      expect(find.text('Excellent! You mastered the polar opposite.'),
          findsOneWidget);
    });
  });
}
