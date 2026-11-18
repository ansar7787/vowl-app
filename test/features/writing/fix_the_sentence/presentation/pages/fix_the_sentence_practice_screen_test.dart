import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_practice_screen.dart';

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

  group('FixTheSentencePracticeScreen', () {
    testWidgets(
      'renders Typo & Error Surgeon Gym, selects replacement, checks answer and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const FixTheSentencePracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FixTheSentencePracticeScreen), findsOneWidget);
        expect(find.text('TARGET FOR REPAIR'), findsOneWidget);
        expect(
          find.text('SELECT THE CORRECT REPLACEMENT WORD:'),
          findsOneWidget,
        );

        // Select the correct option ("plays")
        final playsOptionFinder = find.text('plays');
        expect(playsOptionFinder, findsOneWidget);
        await tester.tap(playsOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Surgical Fix
        final checkFinder = find.text('Check Surgical Fix');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'Repair Successful!' ||
                    w.data == 'Incorrect Substitution'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
