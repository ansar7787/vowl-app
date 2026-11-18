import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/pages/clause_connector_learn_screen.dart';

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

  group('ClauseConnectorLearnScreen', () {
    testWidgets(
      'renders Clause Bridge Engine, architecture, sentence, rule explanation, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ClauseConnectorLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ClauseConnectorLearnScreen), findsOneWidget);
        expect(find.text('Clause Bridge Engine'), findsOneWidget);
        expect(find.text('SYNTACTIC BRIDGE ARCHITECTURE'), findsOneWidget);
        expect(find.text('UNIFIED COMPLEX SENTENCE'), findsOneWidget);
        expect(find.text('HOW THE BRIDGE LINKS CLAUSES'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT CLAUSE BRIDGE'), findsOneWidget);

        // Tap NEXT CLAUSE BRIDGE
        final nextFinder = find.textContaining('NEXT CLAUSE BRIDGE');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Bridge 2 of'), findsOneWidget);
      },
    );
  });
}
