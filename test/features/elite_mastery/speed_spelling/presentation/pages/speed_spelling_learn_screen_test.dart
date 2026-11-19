import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_learn_screen.dart';

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

  group('SpeedSpellingLearnScreen', () {
    testWidgets(
      'renders orthography vault, target word, phoneme analysis, audio button, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeedSpellingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeedSpellingLearnScreen), findsOneWidget);
        expect(find.text('Speed Spelling'), findsOneWidget);
        expect(find.text('ORTHOGRAPHY PATTERN'), findsOneWidget);
        expect(find.text('PHONEME-GRAPHEME ANALYSIS'), findsOneWidget);

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
          const SpeedSpellingLearnScreen(level: 1),
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
          const SpeedSpellingLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
