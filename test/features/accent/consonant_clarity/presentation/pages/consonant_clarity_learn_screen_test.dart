import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_learn_screen.dart';

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

  group('ConsonantClarityLearnScreen', () {
    testWidgets(
      'renders target card, acoustic radar, mechanics card, airflow families, coach advice and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ConsonantClarityLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ConsonantClarityLearnScreen), findsOneWidget);
        expect(find.text('The Consonant Lab'), findsOneWidget);
        expect(find.byKey(const Key('consonant_learn_target_card')), findsOneWidget);
        expect(find.text('ACOUSTIC RADAR: VOICING & AIRFLOW'), findsOneWidget);
        expect(find.text('Mouth Position & Mechanics'), findsOneWidget);
        expect(find.text('CONSONANT AIRFLOW FAMILIES'), findsOneWidget);
        expect(find.text('PHONETIC COACH TIP'), findsOneWidget);

        // Check listen button
        expect(
          find.byKey(const Key('consonant_learn_listen_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('consonant_learn_listen_button')));
        await tester.pumpAndSettle();

        // Tap action button (START PRACTICE)
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
