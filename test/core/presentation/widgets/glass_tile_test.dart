import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

void main() {
  Widget createWidgetForTesting({required Widget child}) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('GlassTile Widget Tests', () {
    testWidgets('should render child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: const GlassTile(
          child: Text('Test Child'),
        ),
      ));

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should apply provided borderRadius', (WidgetTester tester) async {
      final borderRadius = BorderRadius.circular(16);
      await tester.pumpWidget(createWidgetForTesting(
        child: GlassTile(
          borderRadius: borderRadius,
          child: const SizedBox(),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(borderRadius));
    });

    testWidgets('should use PremiumStyle colors in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: const Scaffold(
              body: GlassTile(
                usePremiumStyle: true,
                child: SizedBox(),
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      
      final gradient = decoration.gradient as LinearGradient;
      // In dark mode, premium style uses white/white/black with low alpha
      expect(gradient.colors.length, equals(3));
    });
  });
}
