import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_practice_screen.dart';

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

  group('AudioSentenceOrderPracticeScreen', () {
    testWidgets(
      'renders audio prompt, selects option, checks answer and displays feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const AudioSentenceOrderPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AudioSentenceOrderPracticeScreen), findsOneWidget);
        expect(find.text('Audio Jigsaw Gym'), findsOneWidget);
        expect(find.text('SPOKEN SENTENCE'), findsOneWidget);

        // Check listen audio button
        expect(
          find.byKey(const Key('practice_audio_button')),
          findsOneWidget,
        );

        // Select the first option
        final firstOptionFinder = find.byKey(const Key('practice_option_0'));
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Answer button
        final checkFinder = find.byKey(const Key('practice_check_button'));
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'Sequence Confirmed!' ||
                    widget.data == 'Disordered Cadence'),
          ),
          findsOneWidget,
        );

        // Tap Continue / Next
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
