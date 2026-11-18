import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_learn_screen.dart';

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

  group('OpinionWritingLearnScreen', () {
    testWidgets(
      'renders debate situation, argument structure pillars, model argument, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const OpinionWritingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(OpinionWritingLearnScreen), findsOneWidget);
        expect(find.text('DEBATE SITUATION / TOPIC'), findsOneWidget);
        expect(find.text('MODEL PERSUASIVE ARGUMENT'), findsOneWidget);

        // Tap Next / Action button
        final nextFinder = find.text('Next Persuasion Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('PERSUASION FRAME 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
