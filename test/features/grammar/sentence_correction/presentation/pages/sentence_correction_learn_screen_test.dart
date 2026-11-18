import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/pages/sentence_correction_learn_screen.dart';

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

  group('SentenceCorrectionLearnScreen', () {
    testWidgets(
      'renders diagnosis pill, corrected and faulty sentences, rule explanation, and advances to next diagnosis',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SentenceCorrectionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SentenceCorrectionLearnScreen), findsOneWidget);
        expect(find.textContaining('DIAGNOSIS: INCORRECT VERB'), findsOneWidget);
        expect(find.text('CORRECTED & NATURAL'), findsOneWidget);
        expect(find.text('FAULTY DRAFT'), findsOneWidget);
        expect(find.text('WHY THIS SOUNDS AWKWARD TO NATIVE EARS'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT DIAGNOSIS'), findsOneWidget);

        // Tap NEXT DIAGNOSIS
        final nextFinder = find.textContaining('NEXT DIAGNOSIS');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Diagnosis 2 of'), findsOneWidget);
      },
    );
  });
}
