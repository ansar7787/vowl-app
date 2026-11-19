import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_learn_screen.dart';

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

  group('SyllableStressLearnScreen', () {
    testWidgets(
      'renders syllable stress visualizer, metrical rules, pro-tip and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SyllableStressLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SyllableStressLearnScreen), findsOneWidget);
        expect(find.text('The Beat Box'), findsOneWidget);
        expect(find.text('METRICAL STRESS RULE'), findsOneWidget);
        expect(find.text('BEAT BOX PRO-TIP'), findsOneWidget);

        // Check listen button
        expect(
          find.byKey(const Key('learn_listen_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('learn_listen_button')));
        await tester.pumpAndSettle();

        // Tap action button (next / start practice)
        final actionButton = find.byType(ElevatedButton);
        if (actionButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(actionButton.last);
          await tester.tap(actionButton.last);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
