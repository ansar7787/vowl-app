import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/pages/clause_connector_practice_screen.dart';

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

  group('ClauseConnectorPracticeScreen', () {
    testWidgets(
      'renders instruction, sentence with blank, selects correct connector, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ClauseConnectorPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ClauseConnectorPracticeScreen), findsOneWidget);
        expect(find.text('CONNECT THE CLAUSES'), findsOneWidget);
        expect(find.text('SELECT THE OPTIMAL CONNECTOR:'), findsOneWidget);
        expect(find.text('and'), findsOneWidget);

        // Tap 'and' (correct answer for level 1 quest 1)
        final correctFinder = find.text('and');
        await tester.ensureVisible(correctFinder);
        await tester.tap(correctFinder);
        await tester.pumpAndSettle();

        expect(find.text('SYNTACTIC BRIDGE LOCKED!'), findsOneWidget);
        expect(find.text('COMPLETED SENTENCE'), findsOneWidget);
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
