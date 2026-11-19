import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_practice_screen.dart';

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

  group('StoryBuilderPracticeScreen', () {
    testWidgets(
      'renders premise, selects option, evaluates sequence, displays explanation and continues',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const StoryBuilderPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(StoryBuilderPracticeScreen), findsOneWidget);
        expect(find.text('Story Builder Practice'), findsOneWidget);
        expect(find.text('PLOT ARCHITECT'), findsOneWidget);

        // Select first option
        final firstOptionFinder = find.byKey(const Key('practice_option_0'));
        expect(firstOptionFinder, findsOneWidget);
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Evaluate Sequence button
        final checkFinder = find.byKey(const Key('practice_check_button'));
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify explanation card appears
        expect(find.byKey(const Key('practice_explanation_card')), findsOneWidget);

        // Tap audio button on explanation card
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
          const StoryBuilderPracticeScreen(level: 1),
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
          const StoryBuilderPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
