import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/conditionals/presentation/pages/conditionals_learn_screen.dart';

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

  group('ConditionalsLearnScreen', () {
    testWidgets(
      'renders Multiverse Tree Engine, condition trigger, consequence, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ConditionalsLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ConditionalsLearnScreen), findsOneWidget);
        expect(find.text('Multiverse Tree'), findsOneWidget);
        expect(find.text('MULTIVERSE BRANCH'), findsOneWidget);
        expect(find.text('SYNTACTIC PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER INTUITION'), findsOneWidget);
        expect(find.textContaining('NEXT BRANCH CARD'), findsOneWidget);

        // Tap NEXT BRANCH CARD
        final nextFinder = find.textContaining('NEXT BRANCH CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
