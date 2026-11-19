import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_learn_screen.dart';

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

  group('ShadowingChallengeLearnScreen', () {
    testWidgets(
      'renders target phrase, protocol card, tri-pillar rules, coach advice and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ShadowingChallengeLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ShadowingChallengeLearnScreen), findsOneWidget);
        expect(find.text('The Echo Chamber'), findsOneWidget);
        expect(find.byKey(const Key('shadowing_learn_target_card')), findsOneWidget);
        expect(find.text('The 0.2s Shadowing Protocol'), findsOneWidget);
        expect(find.text('TRI-PILLAR SHADOWING RULES'), findsOneWidget);
        expect(find.text('COACH ADVICE'), findsOneWidget);

        // Check listen button
        expect(
          find.byKey(const Key('shadowing_learn_listen_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('shadowing_learn_listen_button')));
        await tester.pumpAndSettle();

        // Tap a speed selector chip (0.75x)
        final speedChipFinder = find.byKey(const Key('shadowing_learn_speed_chip_0.75'));
        if (speedChipFinder.evaluate().isNotEmpty) {
          await tester.tap(speedChipFinder);
          await tester.pumpAndSettle();
        }

        // Tap action button (START PRACTICE)
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
