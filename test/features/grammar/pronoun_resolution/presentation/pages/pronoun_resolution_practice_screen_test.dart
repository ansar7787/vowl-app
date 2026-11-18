import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_practice_screen.dart';

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

  group('PronounResolutionPracticeScreen', () {
    testWidgets(
      'renders question, selects correct antecedent "Priya", reveals clarity locked, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PronounResolutionPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PronounResolutionPracticeScreen), findsOneWidget);
        expect(find.text('CONTEXT PASSAGE'), findsOneWidget);
        expect(
          find.text('Mr. Osei waited while Priya filled in the form, and then she signed it at the bottom.'),
          findsOneWidget,
        );
        expect(find.text("Who or what does 'she' refer to?"), findsOneWidget);
        expect(find.text('Priya'), findsOneWidget);

        // Tap the correct antecedent option "Priya"
        final correctFinder = find.text('Priya');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('CLARITY LOCKED!'), findsOneWidget);
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
