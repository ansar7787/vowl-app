import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/pages/preposition_choice_learn_screen.dart';

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

  group('PrepositionChoiceLearnScreen', () {
    testWidgets(
      'renders Preposition Radar, spatial hierarchy, complete sentence, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PrepositionChoiceLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PrepositionChoiceLearnScreen), findsOneWidget);
        expect(find.text('Preposition Radar'), findsOneWidget);
        expect(find.text('SPATIAL & TEMPORAL HIERARCHY'), findsOneWidget);
        expect(find.text('IN'), findsOneWidget);
        expect(find.text('NATURAL SENTENCE'), findsOneWidget);
        expect(find.text('PREPOSITION ANCHOR'), findsOneWidget);
        expect(find.text('GRAMMAR PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER INTUITION'), findsOneWidget);
        expect(find.textContaining('NEXT PREPOSITION CARD'), findsOneWidget);

        // Tap NEXT PREPOSITION CARD
        final nextFinder = find.textContaining('NEXT PREPOSITION CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
