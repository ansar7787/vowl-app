import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/pages/tense_mastery_learn_screen.dart';

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

  group('TenseMasteryLearnScreen', () {
    testWidgets(
      'renders timeline orientation, observe sentence card, mechanism breakdown, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const TenseMasteryLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TenseMasteryLearnScreen), findsOneWidget);
        expect(find.textContaining('TIMELINE MAPPING'), findsOneWidget);
        expect(find.text('TIMELINE ORIENTATION'), findsOneWidget);
        expect(find.text('PAST'), findsOneWidget);
        expect(find.text('PRESENT'), findsOneWidget);
        expect(find.text('FUTURE'), findsOneWidget);
        expect(find.text('OBSERVE THE SENTENCE'), findsOneWidget);
        expect(find.text('HOW THE TENSE OPERATES'), findsOneWidget);
        expect(find.text('TEMPORAL MARKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT TIMELINE CARD'), findsOneWidget);

        // Tap NEXT TIMELINE CARD
        final nextFinder = find.textContaining('NEXT TIMELINE CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Concept 2 of'), findsOneWidget);
      },
    );
  });
}
