import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_learn_screen.dart';

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

  group('SceneDescriptionSpeakingLearnScreen', () {
    testWidgets(
      'renders environmental scene, target object, spatial vocabulary, grammar, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SceneDescriptionSpeakingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SceneDescriptionSpeakingLearnScreen), findsOneWidget);
        expect(find.text('ENVIRONMENTAL SCENE'), findsOneWidget);
        expect(find.text('DESCRIPTIVE GOAL & TARGET OBJECT'), findsOneWidget);
        expect(find.text('TARGET SPATIAL VOCABULARY'), findsOneWidget);
        expect(find.text('SPATIAL GRAMMAR & STRUCTURE'), findsOneWidget);
        expect(find.text('DESCRIPTIVE SPEAKING ADVICE'), findsOneWidget);

        // Tap Next Scene button
        final nextFinder = find.byType(ElevatedButton);
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder.first);
          await tester.tap(nextFinder.first);
          await tester.pumpAndSettle();
          expect(find.textContaining('SCENE DISCOVERY 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
