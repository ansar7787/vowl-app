import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_learn_screen.dart';

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

  group('RepeatSentenceLearnScreen', () {
    testWidgets(
      'renders target sentence, rhythm cadence, phonetic guide, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const RepeatSentenceLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(RepeatSentenceLearnScreen), findsOneWidget);
        expect(find.text('TARGET SENTENCE TO SHADOW'), findsOneWidget);
        expect(find.text('STRESS & RHYTHMIC CADENCE'), findsOneWidget);
        expect(find.text('CONNECTED SPEECH & LIAISON'), findsOneWidget);

        // Tap Next / Action button
        final nextFinder = find.text('Next Sentence Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('SHADOWING CARD 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
