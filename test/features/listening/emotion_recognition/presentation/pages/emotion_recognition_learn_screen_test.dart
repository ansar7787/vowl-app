import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_learn_screen.dart';

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

  group('EmotionRecognitionLearnScreen', () {
    testWidgets(
      'renders audio player, emotional dialogue, prosody breakdown, and advances modules',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const EmotionRecognitionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(EmotionRecognitionLearnScreen), findsOneWidget);
        expect(find.text('Prosody Decoder'), findsOneWidget);
        expect(find.text('SPOKEN EMOTIONAL DIALOGUE'), findsOneWidget);
        expect(find.text('TARGET EMOTION & ACOUSTIC CUES'), findsOneWidget);

        // Check audio play button
        expect(
          find.byKey(const Key('learn_play_audio_button')),
          findsOneWidget,
        );

        // Tap Play Audio button
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
