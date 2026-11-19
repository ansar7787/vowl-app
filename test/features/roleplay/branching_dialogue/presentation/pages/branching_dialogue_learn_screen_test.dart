import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_learn_screen.dart';

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

  group('BranchingDialogueLearnScreen', () {
    testWidgets(
      'renders scenario card, optimal response, strategy card, audio button and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const BranchingDialogueLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(BranchingDialogueLearnScreen), findsOneWidget);
        expect(find.text('Branching Dialogue'), findsOneWidget);
        expect(find.byKey(const Key('dialogue_learn_persona_card')), findsOneWidget);
        expect(find.byKey(const Key('dialogue_learn_optimal_card')), findsOneWidget);
        expect(find.byKey(const Key('dialogue_learn_strategy_card')), findsOneWidget);

        // Check listen button
        final audioBtn = find.byKey(const Key('dialogue_learn_audio_btn'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pumpAndSettle();

        // Tap action button (NEXT STRATEGY or START PRACTICE)
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
