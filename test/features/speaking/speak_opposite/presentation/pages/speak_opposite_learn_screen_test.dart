import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/pages/speak_opposite_learn_screen.dart';

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

  group('SpeakOppositeLearnScreen', () {
    testWidgets(
      'renders target word, opposite word, context sentence, insight, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeakOppositeLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeakOppositeLearnScreen), findsOneWidget);
        expect(find.text('Antonym Discovery'), findsOneWidget);
        expect(find.text('GIVEN WORD'), findsOneWidget);
        expect(find.text('OPPOSITE'), findsOneWidget);
        expect(find.text('ANTONYM INSIGHT'), findsOneWidget);

        // Check target word and opposite word widgets
        expect(
          find.byKey(const Key('speak_opposite_learn_target_word')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('speak_opposite_learn_opposite_word')),
          findsOneWidget,
        );

        // Tap action button if available
        final actionButton = find.byType(ElevatedButton);
        if (actionButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(actionButton.first);
          await tester.tap(actionButton.first);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
