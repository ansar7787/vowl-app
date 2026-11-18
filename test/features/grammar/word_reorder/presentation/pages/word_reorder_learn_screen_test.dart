import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/pages/word_reorder_learn_screen.dart';

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

  group('WordReorderLearnScreen', () {
    testWidgets(
      'renders syntax pattern badge, ordered syntax blocks, rule explanation, and advances to next formula',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const WordReorderLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(WordReorderLearnScreen), findsOneWidget);
        expect(find.textContaining('PATTERN: S-V'), findsOneWidget);
        expect(find.text('ORDERED SYNTAX BLOCKS'), findsOneWidget);
        expect(find.text('WHY THIS ORDER WORKS'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT FORMULA'), findsOneWidget);

        // Tap NEXT FORMULA
        final nextFinder = find.textContaining('NEXT FORMULA');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Formula 2 of'), findsOneWidget);
      },
    );
  });
}
