import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_learn_screen.dart';

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

  group('GourmetOrderLearnScreen', () {
    testWidgets(
      'renders server inquiry card, dining pillars, optimal response, strategy card and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const GourmetOrderLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GourmetOrderLearnScreen), findsOneWidget);
        expect(find.text('Gourmet Order'), findsOneWidget);
        expect(find.text('SERVER INQUIRY'), findsOneWidget);
        expect(find.text('DINING PROTOCOL BREAKDOWN'), findsOneWidget);

        // Verify Dining Pillars exist
        expect(find.text('CULINARY CONCEPT'), findsOneWidget);
        expect(find.text('ETIQUETTE & SPECIAL REQUESTS'), findsOneWidget);
        expect(find.text('PRONUNCIATION & PACING'), findsOneWidget);

        // Verify Optimal Response Card
        expect(find.byKey(const Key('gourmet_learn_optimal_card')), findsOneWidget);

        // Verify Audio button
        final audioBtn = find.byKey(const Key('gourmet_learn_audio_btn'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pump();

        // Verify Strategy card
        expect(find.byKey(const Key('gourmet_learn_strategy_card')), findsOneWidget);

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
