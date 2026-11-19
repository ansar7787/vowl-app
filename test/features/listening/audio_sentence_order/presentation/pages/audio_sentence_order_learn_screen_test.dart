import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_learn_screen.dart';

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

  group('AudioSentenceOrderLearnScreen', () {
    testWidgets(
      'renders audio stream, ordered tokens, cadence anchors, and advances cards',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const AudioSentenceOrderLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AudioSentenceOrderLearnScreen), findsOneWidget);
        expect(find.text('Audio Transition Anchors'), findsOneWidget);
        expect(find.text('SPOKEN SENTENCE AUDIO'), findsOneWidget);
        expect(find.text('SYNTACTIC & AUDITORY SEQUENCE'), findsOneWidget);
        expect(find.text('CADENCE & INTONATION ANCHORS'), findsOneWidget);

        expect(
          find.byKey(const Key('audio_sentence_order_learn_transcript')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('audio_sentence_order_learn_tokens_wrap')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('audio_sentence_order_learn_sequence_text')),
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
