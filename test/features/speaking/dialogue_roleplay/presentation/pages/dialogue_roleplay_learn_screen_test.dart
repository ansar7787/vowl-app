import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_learn_screen.dart';

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

  group('DialogueRoleplayLearnScreen', () {
    testWidgets(
      'renders partner dialogue, goal, smart replies, etiquette rationale, rhythm advice, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DialogueRoleplayLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DialogueRoleplayLearnScreen), findsOneWidget);
        expect(find.text('ROLEPLAY PARTNER'), findsOneWidget);
        expect(find.text('YOUR CONVERSATIONAL GOAL & REPLY'), findsOneWidget);
        expect(find.text('ACCEPTED CONVERSATIONAL VARIATIONS'), findsOneWidget);
        expect(
          find.text('SOCIAL ETIQUETTE & COMMUNICATIVE RATIONALE'),
          findsOneWidget,
        );
        expect(find.text('RHYTHM & CONVERSATIONAL DELIVERY'), findsOneWidget);

        // Tap Next Scenario button
        final nextFinder = find.byType(ElevatedButton);
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder.first);
          await tester.tap(nextFinder.first);
          await tester.pumpAndSettle();
          expect(find.textContaining('ROLEPLAY SCENE 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
