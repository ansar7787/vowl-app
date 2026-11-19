import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_practice_screen.dart';

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

  group('GourmetOrderPracticeScreen', () {
    testWidgets(
      'renders server prompt, selects option, evaluates response, displays feedback and continues',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const GourmetOrderPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GourmetOrderPracticeScreen), findsOneWidget);
        expect(find.text('Gourmet Order'), findsOneWidget);
        expect(find.text('RESTAURANT CONSULTATION'), findsOneWidget);

        // Check audio button
        final audioBtn = find.byKey(const Key('practice_audio_button'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pumpAndSettle();

        // Select first option
        final firstOptionFinder = find.byKey(const Key('practice_option_0'));
        expect(firstOptionFinder, findsOneWidget);
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Evaluate Response button
        final checkFinder = find.byKey(const Key('practice_check_button'));
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify explanation card appears
        expect(find.byKey(const Key('practice_explanation_card')), findsOneWidget);

        // Verify continue button appears and tap it
        final continueFinder = find.byKey(const Key('practice_continue_button'));
        expect(continueFinder, findsOneWidget);
        await tester.ensureVisible(continueFinder);
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();
      },
    );
  });
}
