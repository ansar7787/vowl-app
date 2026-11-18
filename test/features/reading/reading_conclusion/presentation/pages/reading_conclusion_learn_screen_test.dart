import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/pages/reading_conclusion_learn_screen.dart';

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

  group('ReadingConclusionLearnScreen', () {
    testWidgets(
      'renders Logical Extrapolation Matrix, premise steps, diagnosis, and advances card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadingConclusionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadingConclusionLearnScreen), findsOneWidget);
        expect(find.text('Logical Extrapolation Matrix'), findsOneWidget);
        expect(find.text('SCENARIO PREMISES'), findsOneWidget);
        expect(find.text('PREMISE-TO-CONCLUSION MATRIX'), findsOneWidget);
        expect(find.text('CANDIDATE CONCLUSIONS DIAGNOSIS'), findsOneWidget);

        // Advance to next card
        final nextFinder = find.text('Next Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('Card 2 of'), findsOneWidget);
        }
      },
    );
  });
}
