import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/pages/relative_clauses_learn_screen.dart';

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

  group('RelativeClausesLearnScreen', () {
    testWidgets(
      'renders Information Snap-In Engine, Lego slot, target clause, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const RelativeClausesLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(RelativeClausesLearnScreen), findsOneWidget);
        expect(find.text('Information Snap-In'), findsOneWidget);
        expect(find.text('LEGO SYNTAX SLOT'), findsOneWidget);
        expect(find.text('SYNTACTIC PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER CADENCE'), findsOneWidget);
        expect(find.textContaining('NEXT SNAP CARD'), findsOneWidget);

        // Tap NEXT SNAP CARD
        final nextFinder = find.textContaining('NEXT SNAP CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
