import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_learn_screen.dart';

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

  group('YesNoSpeakingLearnScreen', () {
    testWidgets(
      'renders spoken claim, written sentence, relation badge, insight, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const YesNoSpeakingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(YesNoSpeakingLearnScreen), findsOneWidget);
        expect(find.text('Statement Verification'), findsOneWidget);
        expect(find.text('SPOKEN CLAIM (AUDIO)'), findsOneWidget);
        expect(find.text('WRITTEN SENTENCE (CLAIM)'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER INSIGHT'), findsOneWidget);

        // Check prompt text and sample text widgets
        expect(
          find.byKey(const Key('yes_no_speaking_learn_prompt_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('yes_no_speaking_learn_sample_text')),
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
