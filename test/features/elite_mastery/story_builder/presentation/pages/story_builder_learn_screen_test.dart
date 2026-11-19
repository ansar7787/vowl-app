import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_learn_screen.dart';

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

  group('StoryBuilderLearnScreen', () {
    testWidgets(
      'renders narrative architecture, cohesive discourse passage, audio button, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const StoryBuilderLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(StoryBuilderLearnScreen), findsOneWidget);
        expect(find.text('Story Builder'), findsOneWidget);
        expect(find.text('NARRATIVE ARCHITECTURE'), findsOneWidget);
        expect(find.text('COHESIVE DISCOURSE PASSAGE'), findsOneWidget);

        // Verify Audio button and tap it
        final audioBtn = find.byKey(const Key('learn_audio_button'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pump();

        // Tap Continue/Next button
        final continueBtn = find.byKey(const Key('learn_continue_button'));
        expect(continueBtn, findsOneWidget);
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
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
          const StoryBuilderLearnScreen(level: 1),
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
          const StoryBuilderLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
