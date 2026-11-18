import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/read_and_match/presentation/pages/read_and_match_practice_screen.dart';

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

  group('ReadAndMatchPracticeScreen', () {
    testWidgets(
      'renders Heading Matcher Gym, taps concept, taps definition to pair, checks matches',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadAndMatchPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadAndMatchPracticeScreen), findsOneWidget);
        expect(find.text('Heading Matcher Gym'), findsOneWidget);
        expect(find.textContaining('CONCEPTS & HEADINGS'), findsOneWidget);
        expect(find.text('DEFINITIONS & MEANINGS'), findsOneWidget);
        expect(find.text('Check Matches'), findsOneWidget);

        // Tap the concept "Tired"
        final tiredFinder = find.text('Tired');
        expect(tiredFinder, findsOneWidget);
        await tester.tap(tiredFinder);
        await tester.pumpAndSettle();

        // Tap the definition for Tired
        final defFinder = find.text('Needing rest because your energy is low.');
        expect(defFinder, findsOneWidget);
        await tester.tap(defFinder);
        await tester.pumpAndSettle();

        // Check if pairing badge appears
        expect(find.textContaining('PAIRED WITH: Tired'), findsOneWidget);

        // Tap Check Matches
        final checkFinder = find.text('Check Matches');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback card appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'ALL PAIRS ACCURATELY MATCHED!' ||
                    w.data == 'MATCH MISALIGNMENT'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
