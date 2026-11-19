import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/pages/pitch_modulation_learn_screen.dart';

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

  group('PitchModulationLearnScreen', () {
    testWidgets(
      'renders target utterance, modulation pattern card, perceptual mechanism, coaching tip and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PitchModulationLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PitchModulationLearnScreen), findsOneWidget);
        expect(find.text('Pitch Modulation'), findsOneWidget);
        expect(find.text('MODULATION PATTERN & MEANING'), findsOneWidget);
        expect(find.text('PERCEPTUAL MECHANISM'), findsOneWidget);
        expect(find.text('COACHING TIP'), findsOneWidget);

        // Check listen button
        expect(
          find.byKey(const Key('learn_play_audio_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('learn_play_audio_button')));
        await tester.pumpAndSettle();

        // Tap action button (NEXT PATTERN or START PRACTICE)
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
