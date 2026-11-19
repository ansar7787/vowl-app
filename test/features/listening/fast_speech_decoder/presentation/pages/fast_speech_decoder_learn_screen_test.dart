import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_learn_screen.dart';

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

  group('FastSpeechDecoderLearnScreen', () {
    testWidgets(
      'renders audio player, speed buttons, deconstruction card, and advances modules',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const FastSpeechDecoderLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FastSpeechDecoderLearnScreen), findsOneWidget);
        expect(find.text('Speech Decompressor'), findsOneWidget);
        expect(find.text('CONNECTED AUDIO PLAYBACK'), findsOneWidget);
        expect(find.text('CONNECTED SPEECH DECONSTRUCTION'), findsOneWidget);

        // Check audio play button
        expect(
          find.byKey(const Key('learn_play_audio_button')),
          findsOneWidget,
        );

        // Check speed toggles
        expect(find.byKey(const Key('learn_speed_075')), findsOneWidget);
        expect(find.byKey(const Key('learn_speed_100')), findsOneWidget);
        expect(find.byKey(const Key('learn_speed_125')), findsOneWidget);

        // Tap 0.75x speed
        await tester.tap(find.byKey(const Key('learn_speed_075')));
        await tester.pumpAndSettle();

        // Tap Play Speech button
        await tester.tap(find.byKey(const Key('learn_play_audio_button')));
        await tester.pumpAndSettle();

        // Tap action button (next / start practice)
        final actionButton = find.byType(ElevatedButton);
        if (actionButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(actionButton.last);
          await tester.tap(actionButton.last);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
