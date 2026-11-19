import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_learn_screen.dart';

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

  group('VowelDistinctionLearnScreen', () {
    testWidgets(
      'renders target card, quadrilateral position, tension rules, dimensions matrix, coach advice and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const VowelDistinctionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(VowelDistinctionLearnScreen), findsOneWidget);
        expect(find.text('The Vowel Quadrilateral'), findsOneWidget);
        expect(find.byKey(const Key('vowel_learn_target_card')), findsOneWidget);
        expect(find.text('VOWEL QUADRILATERAL POSITION'), findsOneWidget);
        expect(find.text('Vowel Tension & Articulation'), findsOneWidget);
        expect(find.text('THE THREE ACOUSTIC DIMENSIONS'), findsOneWidget);
        expect(find.text('PHONETIC COACH TIP'), findsOneWidget);

        // Check listen button
        expect(
          find.byKey(const Key('vowel_learn_listen_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('vowel_learn_listen_button')));
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
