import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/widgets/insecure_device_screen.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setViewport(WidgetTester tester, [Size size = const Size(390, 844), double ratio = 2.0]) {
    tester.view.physicalSize = Size(size.width * ratio, size.height * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(() => tester.view.resetPhysicalSize());
  }

  // =========================================================================
  // GROUP 1: Direct Root Mount & Visual Hierarchy
  // =========================================================================
  group('Group 1: Direct Root Mount & Visual Hierarchy', () {
    testWidgets('renders cleanly when mounted directly as root widget (runApp simulation)', (tester) async {
      setViewport(tester);

      // Mount directly without an enclosing MaterialApp or Theme
      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.slate900);
    });

    testWidgets('displays security warning icon with correct color and size', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();

      final iconFinder = find.byIcon(Icons.security_rounded);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, 80.0);
      expect(iconWidget.color, AppColors.gameIncorrect);
      expect(iconWidget.semanticLabel, 'Security warning');
    });

    testWidgets('displays header title, explanatory body, and instruction footer', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();

      expect(find.text('SECURITY ALERT'), findsOneWidget);
      expect(
        find.text(
          'Vowl cannot run on rooted or jailbroken devices to protect the game economy and user data integrity.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Please use a standard device to continue your adventure.'),
        findsOneWidget,
      );
    });
  });

  // =========================================================================
  // GROUP 2: Accessibility & Semantics
  // =========================================================================
  group('Group 2: Accessibility & Semantics', () {
    testWidgets('announces security alert through liveRegion Semantics node', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label == 'Security alert: this device is not supported',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('isolates rendering with RepaintBoundary', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('supports large accessibility text scaling (2.5x) without overflow', (tester) async {
      setViewport(tester, const Size(320, 568));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
          child: const InsecureDeviceScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('SECURITY ALERT'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 3: Viewport Responsiveness
  // =========================================================================
  group('Group 3: Viewport Responsiveness', () {
    testWidgets('compact mobile layout (320x568) renders without overflow', (tester) async {
      setViewport(tester, const Size(320, 568));

      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('SECURITY ALERT'), findsOneWidget);
    });

    testWidgets('standard phone layout (390x844) renders centered and scrollable', (tester) async {
      setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('SECURITY ALERT'), findsOneWidget);
    });

    testWidgets('tablet layout (800x1280) renders without overflow', (tester) async {
      setViewport(tester, const Size(800, 1280), 1.5);

      await tester.pumpWidget(const InsecureDeviceScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('SECURITY ALERT'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 4: Custom Themed Context Compatibility
  // =========================================================================
  group('Group 4: Custom Themed Context Compatibility', () {
    testWidgets('respects outer AppColorTokens when mounted inside a themed application', (tester) async {
      setViewport(tester);

      const customIncorrectColor = Color(0xFFFF5252);
      final customTokens = AppColorTokens.dark.copyWith(
        gameIncorrect: customIncorrectColor,
      );

      await tester.pumpWidget(
        Theme(
          data: ThemeData.dark().copyWith(
            extensions: [customTokens],
          ),
          child: const InsecureDeviceScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      final footerTextFinder = find.text('Please use a standard device to continue your adventure.');
      expect(footerTextFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(footerTextFinder);
      expect(textWidget.style?.color, customIncorrectColor.withValues(alpha: 0.7));
    });
  });
}
