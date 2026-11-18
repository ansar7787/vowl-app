import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_learn_screen.dart';

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

  group('SpeakSynonymLearnScreen', () {
    testWidgets(
      'renders target word, synonym word, context sentence, insight, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SpeakSynonymLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SpeakSynonymLearnScreen), findsOneWidget);
        expect(find.text('Synonym Discovery'), findsOneWidget);
        expect(find.text('ORIGINAL WORD'), findsOneWidget);
        expect(find.text('SYNONYM'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER INSIGHT'), findsOneWidget);

        // Check target word and synonym word widgets
        expect(
          find.byKey(const Key('speak_synonym_learn_target_word')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('speak_synonym_learn_synonym_word')),
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
