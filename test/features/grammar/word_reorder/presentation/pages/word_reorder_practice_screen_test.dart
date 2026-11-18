import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/pages/word_reorder_practice_screen.dart';

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

  group('WordReorderPracticeScreen', () {
    testWidgets(
      'renders assembly dock and word pool, handles wrong assembly, reset, and validates correct word order',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const WordReorderPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(WordReorderPracticeScreen), findsOneWidget);
        expect(find.text('ASSEMBLY DOCK'), findsOneWidget);
        expect(find.text('AVAILABLE WORD BLOCKS'), findsOneWidget);

        // Tap words in wrong order: 'students' -> 'The' -> 'laugh'
        final studentsFinder = find.text('students').first;
        await tester.ensureVisible(studentsFinder);
        await tester.tap(studentsFinder);
        await tester.pumpAndSettle();

        final theFinder = find.text('The').first;
        await tester.ensureVisible(theFinder);
        await tester.tap(theFinder);
        await tester.pumpAndSettle();

        final laughFinder = find.text('laugh').first;
        await tester.ensureVisible(laughFinder);
        await tester.tap(laughFinder);
        await tester.pumpAndSettle();

        expect(
          find.text('Not quite in order. Tap a word to remove it or tap Reset!'),
          findsOneWidget,
        );

        // Tap RESET
        final resetFinder = find.text('RESET');
        await tester.ensureVisible(resetFinder);
        await tester.tap(resetFinder);
        await tester.pumpAndSettle();

        // Tap words in correct order: 'The' -> 'students' -> 'laugh'
        final theCorrectFinder = find.text('The').first;
        await tester.ensureVisible(theCorrectFinder);
        await tester.tap(theCorrectFinder);
        await tester.pumpAndSettle();

        final studentsCorrectFinder = find.text('students').first;
        await tester.ensureVisible(studentsCorrectFinder);
        await tester.tap(studentsCorrectFinder);
        await tester.pumpAndSettle();

        final laughCorrectFinder = find.text('laugh').first;
        await tester.ensureVisible(laughCorrectFinder);
        await tester.tap(laughCorrectFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('English statements begin with the subject'), findsOneWidget);
        expect(find.text('NEXT EXERCISE'), findsOneWidget);
      },
    );
  });
}
