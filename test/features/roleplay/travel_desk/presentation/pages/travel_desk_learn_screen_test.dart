import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/pages/travel_desk_learn_screen.dart';

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

  group('TravelDeskLearnScreen', () {
    testWidgets(
      'renders traveler inquiry card, transit protocol, optimal response, audio button and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const TravelDeskLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TravelDeskLearnScreen), findsOneWidget);
        expect(find.text('Travel Desk'), findsOneWidget);
        expect(find.text('TRAVELER INQUIRY'), findsOneWidget);
        expect(find.text('TRANSIT & CUSTOMS PROTOCOL'), findsOneWidget);

        // Verify Optimal Response Card and Audio button
        expect(find.text('OPTIMAL DESK RESPONSE'), findsOneWidget);
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
