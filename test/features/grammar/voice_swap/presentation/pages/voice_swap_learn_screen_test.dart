import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/pages/voice_swap_learn_screen.dart';

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

  group('VoiceSwapLearnScreen', () {
    testWidgets(
      'renders Perspective Rotator, active/passive duality cards, rule breakdown, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const VoiceSwapLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(VoiceSwapLearnScreen), findsOneWidget);
        expect(find.text('Perspective Rotator'), findsOneWidget);
        expect(find.text('VOICE PERSPECTIVE DUALITY'), findsOneWidget);
        expect(find.text('ACTIVE VOICE (DOER FIRST)'), findsOneWidget);
        expect(find.text('PASSIVE VOICE (RECEIVER FIRST)'), findsOneWidget);
        expect(find.text('HOW THE PERSPECTIVE ROTATES'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT VOICE CARD'), findsOneWidget);

        // Tap NEXT VOICE CARD
        final nextFinder = find.textContaining('NEXT VOICE CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Voice 2 of'), findsOneWidget);
      },
    );
  });
}
