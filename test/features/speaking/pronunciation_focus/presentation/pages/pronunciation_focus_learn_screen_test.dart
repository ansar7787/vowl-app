import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_learn_screen.dart';

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

  group('PronunciationFocusLearnScreen', () {
    testWidgets(
      'renders target phoneme, articulatory mechanics, common pitfalls, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PronunciationFocusLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PronunciationFocusLearnScreen), findsOneWidget);
        expect(find.text('TARGET SOUND & SENTENCE'), findsOneWidget);
        expect(find.text('TARGET PHONEME'), findsOneWidget);
        expect(find.text('PRACTICE SENTENCE'), findsOneWidget);
        expect(find.text('ARTICULATORY MECHANICS & PLACEMENT'), findsOneWidget);
        expect(find.text('COMMON PRONUNCIATION PITFALLS'), findsOneWidget);

        // Tap Next Word Card / Next Step
        final nextFinder = find.byType(ElevatedButton);
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder.first);
          await tester.tap(nextFinder.first);
          await tester.pumpAndSettle();
          expect(find.textContaining('PHONETIC FOCUS 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
