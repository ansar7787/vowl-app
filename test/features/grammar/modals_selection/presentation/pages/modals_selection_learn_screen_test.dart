import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/pages/modals_selection_learn_screen.dart';

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

  group('ModalsSelectionLearnScreen', () {
    testWidgets(
      'renders Modal Meter Engine, intensity gauge, complete sentence, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ModalsSelectionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ModalsSelectionLearnScreen), findsOneWidget);
        expect(find.text('Modal Meter Engine'), findsOneWidget);
        expect(find.text('MODAL STRENGTH & TONE GAUGE'), findsOneWidget);
        expect(find.text('CAN'), findsOneWidget);
        expect(find.text('NATURAL SENTENCE'), findsOneWidget);
        expect(find.text('MODAL ANCHOR'), findsOneWidget);
        expect(find.text('GRAMMAR PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER INTUITION'), findsOneWidget);
        expect(find.textContaining('NEXT MODAL CARD'), findsOneWidget);

        // Tap NEXT MODAL CARD
        final nextFinder = find.textContaining('NEXT MODAL CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
