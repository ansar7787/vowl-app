import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/guess_title/presentation/pages/guess_title_practice_screen.dart';

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

  group('GuessTitlePracticeScreen', () {
    testWidgets(
      'renders Headline Matcher Gym, selects title option, checks answer and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const GuessTitlePracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GuessTitlePracticeScreen), findsOneWidget);
        expect(find.text('Headline Matcher Gym'), findsOneWidget);
        expect(find.text('PASSAGE'), findsOneWidget);
        expect(find.text('CANDIDATE HEADLINES'), findsOneWidget);
        expect(find.text('Check Answer'), findsOneWidget);

        // Tap option A
        final optionAFinder = find.text('A');
        expect(optionAFinder, findsOneWidget);
        await tester.tap(optionAFinder);
        await tester.pumpAndSettle();

        // Tap Check Answer
        final checkFinder = find.text('Check Answer');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Feedback card appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'THESIS ACCURATELY IDENTIFIED!' ||
                    w.data == 'SCOPE MISMATCH'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
