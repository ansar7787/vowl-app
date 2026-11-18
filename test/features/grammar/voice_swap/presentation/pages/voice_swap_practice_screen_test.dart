import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/pages/voice_swap_practice_screen.dart';

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

  group('VoiceSwapPracticeScreen', () {
    testWidgets(
      'renders instruction, sentence to classify, selects Active voice, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const VoiceSwapPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(VoiceSwapPracticeScreen), findsOneWidget);
        expect(find.text('SENTENCE TO CLASSIFY'), findsOneWidget);
        expect(find.text('SELECT THE VOICE PERSPECTIVE:'), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('PASSIVE'), findsOneWidget);

        // Tap 'ACTIVE' (correct answer for level 1 quest 1)
        final correctFinder = find.text('ACTIVE');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('PERSPECTIVE HARMONY LOCKED!'), findsOneWidget);
        expect(find.text('PASSIVE EQUIVALENT:'), findsOneWidget);
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
