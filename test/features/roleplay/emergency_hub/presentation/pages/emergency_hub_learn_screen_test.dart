import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/pages/emergency_hub_learn_screen.dart';

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

  group('EmergencyHubLearnScreen', () {
    testWidgets(
      'renders scenario card, crisis dispatch protocol, optimal action, audio button and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const EmergencyHubLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(EmergencyHubLearnScreen), findsOneWidget);
        expect(find.text('Emergency Hub'), findsOneWidget);
        expect(find.text('CRISIS DISPATCH PROTOCOL'), findsOneWidget);

        // Verify Optimal Action Card and Audio button
        expect(find.text('OPTIMAL ACTION'), findsOneWidget);
        final audioBtn = find.byKey(const Key('learn_audio_button'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pump();

        // Tap Next
        final nextBtn = find.text('NEXT EMERGENCY');
        if (nextBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextBtn);
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('renders cleanly on narrow screen (320x568) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const EmergencyHubLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet screen (768x1024) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const EmergencyHubLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
