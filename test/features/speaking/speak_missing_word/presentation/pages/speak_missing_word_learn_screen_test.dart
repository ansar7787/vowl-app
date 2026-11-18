import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_learn_screen.dart';

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

  group('SpeakMissingWordLearnScreen', () {
    testWidgets(
      'renders target context, missing word highlight, context clues, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeakMissingWordLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeakMissingWordLearnScreen), findsOneWidget);
        expect(find.text('SITUATION WITH MISSING TARGET WORD'), findsOneWidget);
        expect(find.text('TARGET SPOKEN WORD'), findsOneWidget);
        expect(find.text('CONTEXT CLUE & USAGE INSIGHT'), findsOneWidget);
        expect(find.text('ORAL ARTICULATION & DELIVERY'), findsOneWidget);

        // Tap Next Word Card
        final nextFinder = find.text('Next Word Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('WORD DISCOVERY 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
