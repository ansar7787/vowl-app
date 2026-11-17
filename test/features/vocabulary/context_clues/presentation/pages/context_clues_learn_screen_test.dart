import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_learn_screen.dart';

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

  group('ContextCluesLearnScreen', () {
    testWidgets(
        'renders clue archetype header, mystery word, deduced meaning, and case passage',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ContextCluesLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ContextCluesLearnScreen), findsOneWidget);
      expect(find.text('CLUE ARCHETYPE: DEFINITION CLUE'), findsOneWidget);
      expect(find.text('TARGET MYSTERY WORD'), findsOneWidget);
      expect(find.text('AMAZING'), findsOneWidget);
      expect(find.text('DEDUCED CORE MEANING'), findsOneWidget);
      expect(find.text('🎯 Wonderful'), findsOneWidget);
      expect(find.text('CASE EVIDENCE PASSAGE'), findsOneWidget);
      expect(find.text('Next Clue Case ➔'), findsOneWidget);

      // Tap next case
      await tester.tap(find.text('Next Clue Case ➔'));
      await tester.pumpAndSettle();

      // Case 2: ENORMOUS (synonym clue)
      expect(find.text('ENORMOUS'), findsOneWidget);
      expect(find.text('🎯 Huge'), findsOneWidget);
      expect(find.text('CLUE ARCHETYPE: SYNONYM CLUE'), findsOneWidget);
    });
  });
}
