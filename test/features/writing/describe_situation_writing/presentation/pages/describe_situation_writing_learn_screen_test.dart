import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_learn_screen.dart';

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

  group('DescribeSituationWritingLearnScreen', () {
    testWidgets(
      'renders scenario, scene pillars, booster keywords, model description, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DescribeSituationWritingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DescribeSituationWritingLearnScreen), findsOneWidget);
        expect(find.text('OBSERVE THE SCENARIO'), findsOneWidget);
        expect(find.text('SCENE PILLARS & BOOSTER KEYWORDS'), findsOneWidget);
        expect(find.text('Target Descriptive Vocabulary'), findsOneWidget);
        expect(find.text('EXEMPLARY MODEL DESCRIPTION'), findsOneWidget);

        // Tap second scene pillar
        final pillar2Finder = find.text('Pillar 2');
        if (pillar2Finder.evaluate().isNotEmpty) {
          await tester.tap(pillar2Finder);
          await tester.pumpAndSettle();
        }

        // Tap Next Situation Card button
        final nextFinder = find.text('Next Situation Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('SITUATION 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
