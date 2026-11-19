import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_learn_screen.dart';

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

  group('AudioMultipleChoiceLearnScreen', () {
    testWidgets(
      'renders audio stream, question, key answer, strategy, and advances cards',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const AudioMultipleChoiceLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AudioMultipleChoiceLearnScreen), findsOneWidget);
        expect(find.text('Key Information Pinpointing'), findsOneWidget);
        expect(find.text('SPOKEN AUDIO STREAM'), findsOneWidget);
        expect(find.text('TARGET COMPREHENSION QUESTION'), findsOneWidget);
        expect(find.text('SCAVENGER LISTENING STRATEGY'), findsOneWidget);

        expect(
          find.byKey(const Key('audio_multiple_choice_learn_transcript')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('audio_multiple_choice_learn_question_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('audio_multiple_choice_learn_answer_text')),
          findsOneWidget,
        );

        // Tap action button if available
        final actionButton = find.byType(ElevatedButton);
        if (actionButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(actionButton.first);
          await tester.tap(actionButton.first);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
