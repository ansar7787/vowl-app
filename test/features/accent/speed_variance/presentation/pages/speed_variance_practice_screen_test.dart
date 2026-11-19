import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_practice_screen.dart';

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

  group('SpeedVariancePracticeScreen', () {
    testWidgets(
      'renders target sentence, selects pacing option, checks answer and displays explanation',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeedVariancePracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeedVariancePracticeScreen), findsOneWidget);
        expect(find.text('Speed Variance'), findsOneWidget);
        expect(find.textContaining('Look out, that shelf is falling!'), findsWidgets);

        // Check listen button
        expect(
          find.byKey(const Key('practice_play_audio_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('practice_play_audio_button')));
        await tester.pumpAndSettle();

        // Select first option
        final firstOptionFinder = find.byKey(const Key('practice_option_0'));
        expect(firstOptionFinder, findsOneWidget);
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Answer button
        final checkFinder = find.byKey(const Key('practice_check_button'));
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify explanation card appears
        expect(
          find.byKey(const Key('practice_explanation_card')),
          findsOneWidget,
        );

        // Tap Continue / Next button
        final continueFinder =
            find.byKey(const Key('practice_continue_button'));
        expect(continueFinder, findsOneWidget);
        await tester.ensureVisible(continueFinder);
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();
      },
    );
  });
}
