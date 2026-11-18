import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_practice_screen.dart';

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

  group('SpeakSynonymPracticeScreen', () {
    testWidgets(
      'renders target synonym prompt, selects option, checks answer and displays feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeakSynonymPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeakSynonymPracticeScreen), findsOneWidget);
        expect(find.text('FIND SYNONYM FOR'), findsOneWidget);
        expect(
          find.byKey(const Key('speak_synonym_practice_target_word')),
          findsOneWidget,
        );

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

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'EXCELLENT SYNONYM!' ||
                    widget.data == 'KEEP PRACTICING'),
          ),
          findsOneWidget,
        );

        // Tap Next / Finish
        final nextFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data == 'Next Exercise' ||
                  widget.data == 'Finish Practice'),
        );
        expect(nextFinder, findsOneWidget);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();
      },
    );
  });
}
