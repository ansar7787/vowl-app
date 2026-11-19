import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_learn_screen.dart';

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

  group('AudioTrueFalseLearnScreen', () {
    testWidgets(
      'renders spoken stream, statement evaluation card, trap radar, and strategy rule',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const AudioTrueFalseLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AudioTrueFalseLearnScreen), findsOneWidget);
        expect(find.text('Distractor & Trap Alert'), findsOneWidget);
        expect(find.text('SPOKEN AUDIO STREAM'), findsOneWidget);
        expect(find.text('CLAIM UNDER EVALUATION'), findsOneWidget);

        // Check audio play button
        expect(
          find.byKey(const Key('audio_true_false_learn_audio_btn')),
          findsOneWidget,
        );

        // Check statement card
        expect(
          find.byKey(const Key('audio_true_false_learn_statement_card')),
          findsOneWidget,
        );

        // Check rule card
        expect(
          find.byKey(const Key('audio_true_false_learn_rule_card')),
          findsOneWidget,
        );

        // Tap action button to advance or navigate
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
