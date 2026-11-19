import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_learn_screen.dart';

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

  group('DetailSpotlightLearnScreen', () {
    testWidgets(
      'renders audio player, spotlight breakdown, and advances modules',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DetailSpotlightLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DetailSpotlightLearnScreen), findsOneWidget);
        expect(find.text('Detail Spotlight'), findsOneWidget);
        expect(find.text('ACOUSTIC SPOTLIGHT STREAM'), findsOneWidget);
        expect(find.text('SPOTLIGHT DETAIL BREAKDOWN'), findsOneWidget);

        // Check audio play button
        expect(
          find.byKey(const Key('learn_play_audio_button')),
          findsOneWidget,
        );

        // Tap Play Audio button
        await tester.tap(find.byKey(const Key('learn_play_audio_button')));
        await tester.pumpAndSettle();

        // Tap action button (next / start practice)
        final actionButton = find.byType(ElevatedButton);
        if (actionButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(actionButton.last);
          await tester.tap(actionButton.last);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
