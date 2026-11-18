import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_learn_screen.dart';

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

  group('WritingEmailLearnScreen', () {
    testWidgets(
      'renders scenario, 4-part architecture, model email, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const WritingEmailLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(WritingEmailLearnScreen), findsOneWidget);
        expect(find.text('EMAIL SCENARIO & OBJECTIVE'), findsOneWidget);
        expect(find.text('FOUR-PART EMAIL ARCHITECTURE:'), findsOneWidget);
        expect(find.text('ASSEMBLED MODEL EMAIL'), findsOneWidget);

        // Tap Next / Action button
        final nextFinder = find.text('Next Email Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('EMAIL BLUEPRINT 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
