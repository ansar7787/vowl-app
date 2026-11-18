import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/pages/sentence_correction_practice_screen.dart';

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

  group('SentenceCorrectionPracticeScreen', () {
    testWidgets(
      'renders target diagnostic sentence, handles incorrect option, validates correct substitution, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SentenceCorrectionPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SentenceCorrectionPracticeScreen), findsOneWidget);
        expect(find.text('TARGET FOR DIAGNOSIS'), findsOneWidget);
        expect(find.text('The children is playing in the yard.'), findsOneWidget);

        // Tap incorrect option ('am')
        final wrongOptionFinder = find.text('am').first;
        await tester.ensureVisible(wrongOptionFinder);
        await tester.tap(wrongOptionFinder);
        await tester.pumpAndSettle();

        expect(
          find.text('Not the right correction. Try another option!'),
          findsOneWidget,
        );

        // Tap correct option ('are')
        final correctOptionFinder = find.text('are').first;
        await tester.ensureVisible(correctOptionFinder);
        await tester.tap(correctOptionFinder);
        await tester.pumpAndSettle();

        expect(find.text('The children are playing in the yard.'), findsOneWidget);
        expect(find.textContaining('plural form'), findsOneWidget);
        expect(find.text('NEXT EXERCISE'), findsOneWidget);
      },
    );
  });
}
