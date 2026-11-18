import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/pages/find_word_meaning_learn_screen.dart';

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

  group('FindWordMeaningLearnScreen', () {
    testWidgets(
      'renders Context Clue Detective, clue type, target vocabulary, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const FindWordMeaningLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FindWordMeaningLearnScreen), findsOneWidget);
        expect(find.text('Context Clue Detective'), findsOneWidget);
        expect(find.text('INFERENCE CLUE'), findsOneWidget);
        expect(find.text('TARGET VOCABULARY'), findsOneWidget);
        expect(find.text('happy'), findsWidgets);
        expect(find.text('READING STRATEGY'), findsOneWidget);
        expect(find.textContaining('NEXT CLUE CARD'), findsOneWidget);

        // Tap NEXT CLUE CARD
        final nextFinder = find.textContaining('NEXT CLUE CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Card 2 of'), findsOneWidget);
        expect(find.text('difficult'), findsWidgets);
      },
    );
  });
}
