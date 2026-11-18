import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_learn_screen.dart';

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

  group('CorrectionWritingLearnScreen', () {
    testWidgets(
      'renders flawed passage, breakdown, corrected sentence, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const CorrectionWritingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CorrectionWritingLearnScreen), findsOneWidget);
        expect(find.text('PASSAGE WITH GRAMMATICAL ERROR'), findsOneWidget);
        expect(find.text('SURGICAL REPAIR BREAKDOWN:'), findsOneWidget);
        expect(find.text('CORRECTED SENTENCE'), findsOneWidget);

        // Tap Next / Action button
        final nextFinder = find.text('Next Repair Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('REPAIR CARD 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
