import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_learn_screen.dart';

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

  group('GrammarQuestLearnScreen', () {
    testWidgets(
      'renders grammar equation, contrasting patterns, rule explanation, and advances to next rule',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const GrammarQuestLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GrammarQuestLearnScreen), findsOneWidget);
        expect(find.text('GRAMMAR EQUATION'), findsOneWidget);
        expect(find.text('CORRECT & NATURAL'), findsOneWidget);
        expect(find.text('COMMON ERROR / AWKWARD CLASH'), findsOneWidget);
        expect(find.text('WHY THIS RULE WORKS'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT RULE'), findsOneWidget);

        // Tap NEXT RULE
        final nextFinder = find.textContaining('NEXT RULE');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
