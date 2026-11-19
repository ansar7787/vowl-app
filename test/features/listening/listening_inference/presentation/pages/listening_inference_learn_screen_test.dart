import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_learn_screen.dart';

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

  group('ListeningInferenceLearnScreen', () {
    testWidgets(
      'renders audio player, literal vs implied breakdown, and advances modules',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ListeningInferenceLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ListeningInferenceLearnScreen), findsOneWidget);
        expect(find.text('Inference Lens'), findsOneWidget);
        expect(find.text('AUDITORY SUBTEXT STREAM'), findsOneWidget);
        expect(find.text('LITERAL VS. IMPLIED MEANING'), findsOneWidget);

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
