import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_practice_screen.dart';

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

  group('SubjectVerbAgreementPracticeScreen', () {
    testWidgets(
      'renders target blank, handles verb terminal selection, synthesizes completed sentence, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SubjectVerbAgreementPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SubjectVerbAgreementPracticeScreen), findsOneWidget);
        expect(find.text('SENTENCE WITH BLANK'), findsOneWidget);
        expect(find.text('WHICH VERB BALANCES THE SUBJECT?'), findsOneWidget);
        expect(find.text('BAKE'), findsOneWidget);
        expect(find.text('BAKES'), findsOneWidget);

        // Tap 'BAKES' (correct answer for level 1 quest 1)
        final correctFinder = find.text('BAKES');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('PERFECT BALANCE!'), findsOneWidget);
        expect(find.text('COMPLETED SENTENCE'), findsOneWidget);
        expect(
          find.text('The bakery bakes fresh croissants at dawn.'),
          findsOneWidget,
        );
        expect(find.text('NEXT EXERCISE'), findsOneWidget);

        // Tap NEXT EXERCISE
        final nextFinder = find.text('NEXT EXERCISE');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Exercise 2 of'), findsOneWidget);
      },
    );
  });
}
