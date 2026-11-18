import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_learn_screen.dart';

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

  group('SubjectVerbAgreementLearnScreen', () {
    testWidgets(
      'renders equilibrium scale, natural agreement card, rule explanation, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SubjectVerbAgreementLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SubjectVerbAgreementLearnScreen), findsOneWidget);
        expect(find.textContaining('GRAMMAR SCALE'), findsWidgets);
        expect(find.text('SYNTACTIC EQUILIBRIUM'), findsOneWidget);
        expect(find.text('NATURAL AGREEMENT'), findsOneWidget);
        expect(find.text('WHY THE SCALE BALANCES'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT SCALE CARD'), findsOneWidget);

        // Tap NEXT SCALE CARD
        final nextFinder = find.textContaining('NEXT SCALE CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Concept 2 of'), findsOneWidget);
      },
    );
  });
}
