import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/widgets/games/premium_game_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  Widget createWidgetForTesting({required Widget child}) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
      child: child,
    );
  }

  group('PremiumGameHeader Widget Tests', () {
    testWidgets('should render lives count correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: PremiumGameHeader(
          progress: 0.5,
          lives: 3,
          onHint: () {},
          onHintAd: () {},
          onClose: () {},
        ),
      ));

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('should call onClose when close button is tapped', (WidgetTester tester) async {
      bool closed = false;
      await tester.pumpWidget(createWidgetForTesting(
        child: PremiumGameHeader(
          progress: 0.5,
          lives: 3,
          onHint: () {},
          onHintAd: () {},
          onClose: () => closed = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('should show hint button when hintCount is provided', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: PremiumGameHeader(
          progress: 0.5,
          lives: 3,
          hintCount: 5,
          onHint: () {},
          onHintAd: () {},
          onClose: () {},
        ),
      ));

      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should show ad hint button when hintCount is 0', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: PremiumGameHeader(
          progress: 0.5,
          lives: 3,
          hintCount: 0,
          onHint: () {},
          onHintAd: () {},
          onClose: () {},
        ),
      ));

      // When hints are 0, it shows Icons.play_circle_fill_rounded
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });

    testWidgets('should calculate progress bar width correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetForTesting(
        child: PremiumGameHeader(
          progress: 0.5,
          lives: 3,
          onHint: () {},
          onHintAd: () {},
          onClose: () {},
        ),
      ));

      // Wait for implicit animation
      await tester.pump(const Duration(milliseconds: 700));

      final Finder progressBarFinder = find.byType(AnimatedContainer);
      final Size size = tester.getSize(progressBarFinder);

      // (360 - 180) * 0.5 = 90
      expect(size.width, equals(90.0));
    });
  });
}
