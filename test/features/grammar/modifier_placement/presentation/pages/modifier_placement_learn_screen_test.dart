import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/pages/modifier_placement_learn_screen.dart';

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

  group('ModifierPlacementLearnScreen', () {
    testWidgets(
      'renders Modifier Anchor Engine, spotlight, natural attachment, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ModifierPlacementLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ModifierPlacementLearnScreen), findsOneWidget);
        expect(find.text('Modifier Anchor Engine'), findsOneWidget);
        expect(find.text('MODIFIER SPOTLIGHT'), findsOneWidget);
        expect(find.text('NATURAL ATTACHMENT'), findsOneWidget);
        expect(find.text('MISPLACED MODIFIER (AWKWARD)'), findsOneWidget);
        expect(find.text('VISUAL ANCHOR'), findsOneWidget);
        expect(find.text('GRAMMAR PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER INTUITION'), findsOneWidget);
        expect(find.textContaining('NEXT MODIFIER CARD'), findsOneWidget);

        // Tap NEXT MODIFIER CARD
        final nextFinder = find.textContaining('NEXT MODIFIER CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
