import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_practice_screen.dart';

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

  group('EssayDraftingPracticeScreen', () {
    testWidgets(
      'renders topic, selects candidate draft, checks and reveals feedback',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const EssayDraftingPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(EssayDraftingPracticeScreen), findsOneWidget);
        expect(find.text('ESSAY TOPIC'), findsOneWidget);
        expect(find.text('SELECT THE MOST COHESIVE PARAGRAPH ORDER:'), findsOneWidget);

        // Select the first option
        final firstOptionFinder = find.byType(InkWell).first;
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Paragraph Draft
        final checkFinder = find.text('Check Paragraph Draft');
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify feedback appears
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'COMPELLING & COHESIVE ESSAY DRAFT!' ||
                    widget.data == 'DRAFT ANALYSIS & RHETORICAL FEEDBACK'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
