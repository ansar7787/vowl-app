import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_practice_screen.dart';

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

  group('PronunciationFocusPracticeScreen', () {
    testWidgets(
      'renders target sound prompt, selects articulatory option, checks and displays feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PronunciationFocusPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PronunciationFocusPracticeScreen), findsOneWidget);
        expect(find.text('SPOKEN PROMPT'), findsOneWidget);

        // Select the first option
        final firstOptionFinder = find.byKey(const Key('practice_option_0'));
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Answer button
        final checkFinder = find.text('Check Answer');
        expect(checkFinder, findsOneWidget);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback card appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'EXCELLENT ARTICULATION' ||
                    widget.data == 'PHONETIC CORRECTION'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
