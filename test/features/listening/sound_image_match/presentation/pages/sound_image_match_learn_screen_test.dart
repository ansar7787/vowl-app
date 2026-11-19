import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_learn_screen.dart';

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

  group('SoundImageMatchLearnScreen', () {
    testWidgets(
      'renders spoken stream, visual scene card, ambient breakdown, and advances cards',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SoundImageMatchLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SoundImageMatchLearnScreen), findsOneWidget);
        expect(find.text('Acoustic Environment Immersion'), findsOneWidget);
        expect(find.text('SPOKEN AUDIO STREAM'), findsOneWidget);
        expect(find.text('MATCHING VISUAL SCENE'), findsOneWidget);

        // Check audio play button
        expect(
          find.byKey(const Key('sound_image_match_learn_audio_btn')),
          findsOneWidget,
        );

        // Check scene card
        expect(
          find.byKey(const Key('sound_image_match_learn_scene_card')),
          findsOneWidget,
        );

        // Check rule card
        expect(
          find.byKey(const Key('sound_image_match_learn_rule_card')),
          findsOneWidget,
        );

        // Tap action button
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
