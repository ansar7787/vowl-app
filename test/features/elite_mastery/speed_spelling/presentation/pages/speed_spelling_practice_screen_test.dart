import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_practice_screen.dart';

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

  group('SpeedSpellingPracticeScreen', () {
    testWidgets(
      'renders orthography sprint, selects option, checks answer, displays explanation, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeedSpellingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeedSpellingPracticeScreen), findsOneWidget);
        expect(find.text('Speed Spelling Practice'), findsOneWidget);
        expect(find.text('ORTHOGRAPHY SPRINT'), findsOneWidget);

        // Select first option
        final firstOptionFinder = find.byKey(const Key('practice_option_0'));
        expect(firstOptionFinder, findsOneWidget);
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Spelling button
        final checkFinder = find.byKey(const Key('practice_check_button'));
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify explanation card appears
        expect(find.byKey(const Key('practice_explanation_card')), findsOneWidget);

        // Tap audio button if present
        final audioBtn = find.byKey(const Key('practice_audio_button'));
        if (audioBtn.evaluate().isNotEmpty) {
          await tester.tap(audioBtn);
          await tester.pump();
        }

        // Verify continue button appears and tap it
        final continueFinder = find.byKey(const Key('practice_continue_button'));
        expect(continueFinder, findsOneWidget);
        await tester.ensureVisible(continueFinder);
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('renders cleanly on narrow screen (320x568) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const SpeedSpellingPracticeScreen(level: 1),
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
          const SpeedSpellingPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
