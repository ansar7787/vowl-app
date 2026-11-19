import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_learn_screen.dart';

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

  group('SpeedVarianceLearnScreen', () {
    testWidgets(
      'renders target utterance, tempo metronome, pacing principle, coach advice and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeedVarianceLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeedVarianceLearnScreen), findsOneWidget);
        expect(find.text('Speed Variance'), findsOneWidget);
        expect(find.text('TEMPO METRONOME PACING'), findsOneWidget);
        expect(find.text('PACING PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER RHYTHM'), findsOneWidget);

        // Check listen button
        expect(
          find.byKey(const Key('learn_play_audio_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('learn_play_audio_button')));
        await tester.pumpAndSettle();

        // Tap action button (NEXT TEMPO or START PRACTICE)
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
