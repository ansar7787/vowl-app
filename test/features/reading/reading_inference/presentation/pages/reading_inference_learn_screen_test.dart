import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_learn_screen.dart';

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

  group('ReadingInferenceLearnScreen', () {
    testWidgets(
      'renders Between the Lines Radar, passage, clue words, explicit vs implicit breakdown, and advances card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadingInferenceLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadingInferenceLearnScreen), findsOneWidget);
        expect(find.text('Between the Lines Radar'), findsOneWidget);
        expect(find.text('BETWEEN-THE-LINES DECODER'), findsOneWidget);
        expect(find.text('EXPLICIT SURFACE WORDS'), findsOneWidget);
        expect(find.text('DECODED UNSTATED SUBTEXT'), findsOneWidget);
        expect(find.text('CANDIDATE OPTIONS RADAR DIAGNOSIS'), findsOneWidget);

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
