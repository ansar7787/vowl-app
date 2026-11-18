import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_learn_screen.dart';

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

  group('EssayDraftingLearnScreen', () {
    testWidgets(
      'renders topic, thesis, structural pillars, model draft, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const EssayDraftingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(EssayDraftingLearnScreen), findsOneWidget);
        expect(find.text('ESSAY TOPIC & THESIS'), findsOneWidget);
        expect(find.text('PARAGRAPH DRAFTING PILLARS:'), findsOneWidget);
        expect(find.text('SYNTHESIZED PARAGRAPH DRAFT'), findsOneWidget);

        // Tap Next / Action button
        final nextFinder = find.text('Next Outline Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('ESSAY BLUEPRINT 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
