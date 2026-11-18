import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/conditionals/presentation/pages/conditionals_practice_screen.dart';

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

  group('ConditionalsPracticeScreen', () {
    testWidgets(
      'renders question, selects correct option, reveals rationale, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ConditionalsPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ConditionalsPracticeScreen), findsOneWidget);
        expect(find.text('CONDITION TRIGGER'), findsOneWidget);
        expect(find.text('If you touch fire,'), findsOneWidget);
        expect(find.text('you burn yourself.'), findsWidgets);

        // Tap the correct consequence option "you burn yourself."
        final correctFinder = find.text('you burn yourself.').last;
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('TIMELINE WOVEN'), findsOneWidget);
        expect(find.text('TIMELINE HARMONY RATIONALE'), findsOneWidget);
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
