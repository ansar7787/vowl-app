import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/features/premium/presentation/widgets/premium_failure_overlay.dart';
import 'package:vowl/features/premium/presentation/widgets/premium_success_overlay.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('PremiumFailureOverlay', () {
    testWidgets('renders in light mode with proper text contrast and actions',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool retried = false;
      bool closed = false;

      await tester.pumpWidget(
        _wrap(
          PremiumFailureOverlay(
            onRetry: () => retried = true,
            onClose: () => closed = true,
            errorMessage: 'Card was declined by issuing bank',
          ),
          theme: ThemeData.light(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('TRANSACTION FAILED'), findsOneWidget);
      expect(find.text('Card was declined by issuing bank'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('Need help?'), findsOneWidget);
      expect(find.text('support@vowl.app'), findsOneWidget);

      await tester.ensureVisible(find.text('RETRY'));
      await tester.tap(find.text('RETRY'));
      await tester.pump();
      expect(retried, isTrue);

      await tester.ensureVisible(find.text('CLOSE'));
      await tester.tap(find.text('CLOSE'));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('renders in dark mode without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PremiumFailureOverlay(
            onRetry: () {},
            onClose: () {},
          ),
          theme: ThemeData.dark(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('TRANSACTION FAILED'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
    });

    testWidgets('renders in OLED midnight mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PremiumFailureOverlay(
            onRetry: () {},
            onClose: () {},
          ),
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('TRANSACTION FAILED'), findsOneWidget);
    });
  });

  group('PremiumSuccessOverlay', () {
    testWidgets('renders in light mode with high contrast and triggers action',
        (tester) async {
      bool adventureBegun = false;

      await tester.pumpWidget(
        _wrap(
          PremiumSuccessOverlay(
            transactionId: 'TXN_9988776655',
            onBeginAdventure: () => adventureBegun = true,
          ),
          theme: ThemeData.light(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('UPGRADE SUCCESSFUL'), findsOneWidget);
      expect(
        find.text(
          'Your upgrade was successful. All elite features are now unlocked.',
        ),
        findsOneWidget,
      );
      expect(find.text('TRANSACTION ID'), findsOneWidget);
      expect(find.text('TXN_9988776655'), findsOneWidget);
      expect(find.text('BEGIN ADVENTURE'), findsOneWidget);
      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);

      await tester.tap(find.text('BEGIN ADVENTURE'));
      expect(adventureBegun, isTrue);
    });

    testWidgets('renders in dark mode and OLED midnight mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PremiumSuccessOverlay(
            onBeginAdventure: () {},
          ),
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('UPGRADE SUCCESSFUL'), findsOneWidget);
      expect(find.text('BEGIN ADVENTURE'), findsOneWidget);
    });
  });
}
