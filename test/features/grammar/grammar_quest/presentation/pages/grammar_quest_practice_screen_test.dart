import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_practice_screen.dart';

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

  group('GrammarQuestPracticeScreen', () {
    testWidgets(
      'renders sentence prompt, handles incorrect tap, validates correct answer, and enables forward step',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const GrammarQuestPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GrammarQuestPracticeScreen), findsOneWidget);
        expect(find.text('SENTENCE PROMPT'), findsOneWidget);
        expect(find.text('I ___ from Brazil.'), findsOneWidget);

        // Tap wrong option ('is')
        final wrongOptionFinder = find.text('is');
        await tester.ensureVisible(wrongOptionFinder);
        await tester.tap(wrongOptionFinder);
        await tester.pumpAndSettle();

        expect(find.text('Not quite right. Try another option!'), findsOneWidget);

        // Tap correct option ('am')
        final correctOptionFinder = find.text('am');
        await tester.ensureVisible(correctOptionFinder);
        await tester.tap(correctOptionFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('always takes'), findsOneWidget);
        expect(find.text('NEXT EXERCISE'), findsOneWidget);
      },
    );
  });
}
