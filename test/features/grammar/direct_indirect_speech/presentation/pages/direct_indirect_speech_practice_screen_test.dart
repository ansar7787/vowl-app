import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/pages/direct_indirect_speech_practice_screen.dart';

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

  group('DirectIndirectSpeechPracticeScreen', () {
    testWidgets(
      'renders direct quote, selects correct reported speech, checks and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DirectIndirectSpeechPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DirectIndirectSpeechPracticeScreen), findsOneWidget);
        expect(find.text('ORIGINAL DIRECT QUOTE'), findsOneWidget);
        expect(find.textContaining('Maria said'), findsWidgets);

        // Tap the correct reported speech option
        final correctOptionFinder = find.text('Maria said that she walked to school every day.').first;
        await tester.ensureVisible(correctOptionFinder);
        await tester.tap(correctOptionFinder);
        await tester.pumpAndSettle();

        expect(find.text('PROPOSED REPORTED SPEECH'), findsOneWidget);
        expect(find.text('CHECK TRANSFORMATION'), findsOneWidget);

        // Tap CHECK TRANSFORMATION
        final checkFinder = find.text('CHECK TRANSFORMATION');
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        expect(find.text('WELL CONVERTED!'), findsOneWidget);
        expect(find.text('NEXT EXERCISE →'), findsOneWidget);

        // Tap NEXT EXERCISE →
        final nextFinder = find.text('NEXT EXERCISE →');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Exercise 2 of'), findsOneWidget);
      },
    );
  });
}
