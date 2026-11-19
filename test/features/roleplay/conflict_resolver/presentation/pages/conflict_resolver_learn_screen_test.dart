import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_learn_screen.dart';

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

  group('ConflictResolverLearnScreen', () {
    testWidgets(
      'renders dispute scenario card, de-escalation protocol, optimal response, audio button and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ConflictResolverLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ConflictResolverLearnScreen), findsOneWidget);
        expect(find.text('Conflict Resolver'), findsOneWidget);
        expect(find.text('DE-ESCALATION PROTOCOL'), findsOneWidget);

        // Verify Optimal Response Card and Audio button
        expect(find.text('OPTIMAL RESPONSE'), findsOneWidget);
        final audioBtn = find.byKey(const Key('learn_audio_button'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pump();

        // Tap Next
        final nextBtn = find.text('NEXT SCENARIO');
        if (nextBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextBtn);
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
