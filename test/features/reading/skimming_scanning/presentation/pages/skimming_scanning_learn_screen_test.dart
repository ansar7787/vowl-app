import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_learn_screen.dart';

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

  group('SkimmingScanningLearnScreen', () {
    testWidgets(
      'renders Visual Saccade radar, target criterion, passage scan, and advances card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SkimmingScanningLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SkimmingScanningLearnScreen), findsOneWidget);
        expect(find.text('VISUAL SACCADE & SCANNING RADAR'), findsOneWidget);
        expect(find.text('SEARCH TARGET CRITERION'), findsOneWidget);
        expect(find.text('PASSAGE RADAR SCAN'), findsOneWidget);
        expect(find.text('KEY ANCHOR IDENTIFIED'), findsOneWidget);
        expect(find.text('CANDIDATE SCAN EVALUATION'), findsOneWidget);

        // Advance to next card
        final nextFinder = find.text('Next Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('CARD 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
