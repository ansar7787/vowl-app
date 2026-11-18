import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/pages/conjunctions_learn_screen.dart';

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

  group('ConjunctionsLearnScreen', () {
    testWidgets(
      'renders Traffic Lights of Logic Engine, junction signal, target conjunction, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ConjunctionsLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ConjunctionsLearnScreen), findsOneWidget);
        expect(find.text('Traffic Lights of Logic'), findsOneWidget);
        expect(find.text('JUNCTION SIGNAL'), findsOneWidget);
        expect(find.text('SYNTACTIC PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER CADENCE'), findsOneWidget);
        expect(find.textContaining('NEXT LOGIC CARD'), findsOneWidget);

        // Tap NEXT LOGIC CARD
        final nextFinder = find.textContaining('NEXT LOGIC CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
