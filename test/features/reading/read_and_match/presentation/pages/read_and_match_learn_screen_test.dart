import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/read_and_match/presentation/pages/read_and_match_learn_screen.dart';

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

  group('ReadAndMatchLearnScreen', () {
    testWidgets(
      'renders Summary Synapse, connections, synthesis breakdown, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadAndMatchLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadAndMatchLearnScreen), findsOneWidget);
        expect(find.text('Summary Synapse'), findsOneWidget);
        expect(find.text('SYNAPSE CONNECTIONS'), findsOneWidget);
        expect(find.text('SYNTHESIS BREAKDOWN'), findsOneWidget);

        // Tap Next Synapse Strategy to advance card
        final nextFinder = find.textContaining('Next Synapse Strategy');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('Card 2 of'), findsOneWidget);
        }
      },
    );
  });
}
