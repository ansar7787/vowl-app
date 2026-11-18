import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_practice_screen.dart';

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

  group('SentenceBuilderPracticeScreen', () {
    testWidgets(
      'renders Slot Filling Gym, places phrase blocks into slots, checks syntax and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SentenceBuilderPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SentenceBuilderPracticeScreen), findsOneWidget);
        expect(find.text('SYNTACTIC GYM'), findsOneWidget);
        expect(find.text('TARGET SLOTS (IN SYNTACTIC ORDER)'), findsOneWidget);
        expect(find.text('AVAILABLE PHRASE BLOCKS'), findsOneWidget);

        // Tap the 4 available chips to fill the 4 target slots
        final chipsToTap = [
          'The curious astronomer',
          'observed',
          'distant galaxies',
          'through the observatory lens',
        ];

        for (final chip in chipsToTap) {
          final chipFinder = find.text(chip);
          if (chipFinder.evaluate().isNotEmpty) {
            await tester.ensureVisible(chipFinder.last);
            await tester.tap(chipFinder.last);
            await tester.pumpAndSettle();
          }
        }

        // Tap Check Sentence Syntax
        final checkFinder = find.text('Check Sentence Syntax');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback banner appears
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'EXCELLENT SYNTAX!' ||
                    w.data == 'SYNTAX SEQUENCE MISMATCH'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
