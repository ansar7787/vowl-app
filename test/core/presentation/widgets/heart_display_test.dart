import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/widgets/roleplay/roleplay_ui_components.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  Widget createWidgetForTesting({required Widget child}) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('HeartDisplay Widget Tests', () {
    testWidgets('should display correct number of filled and empty hearts', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: const HeartDisplay(count: 2, maxHearts: 3),
      ));
      await tester.pumpAndSettle();

      // Filled hearts use Icons.favorite_rounded
      // Empty hearts use Icons.favorite_border_rounded
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(1));
    });

    testWidgets('should display 0 filled hearts when count is 0', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: const HeartDisplay(count: 0, maxHearts: 5),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(5));
    });

    testWidgets('should handle maxHearts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: const HeartDisplay(count: 5, maxHearts: 5),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });
  });
}
