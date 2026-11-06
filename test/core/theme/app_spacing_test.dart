import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing Tests', () {
    testWidgets('AppSpacing scales correctly on standard 375x812 screen',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      // Verify Screen Tokens (at 1.0 scale ratio: 375 / 375 = 1)
      expect(AppSpacing.screen, equals(20.0));
      expect(AppSpacing.compact, equals(16.0));
      expect(AppSpacing.spacious, equals(24.0));

      // Verify Card Tokens
      expect(AppSpacing.card, equals(16.0));
      expect(AppSpacing.cardCompact, equals(12.0));
      expect(AppSpacing.cardSpacious, equals(20.0));

      // Verify Spacing Gaps
      expect(AppSpacing.xs, equals(4.0));
      expect(AppSpacing.sm, equals(8.0));
      expect(AppSpacing.md, equals(12.0));
      expect(AppSpacing.base, equals(16.0));
      expect(AppSpacing.lg, equals(20.0));
      expect(AppSpacing.xl, equals(24.0));
      expect(AppSpacing.xxl, equals(32.0));

      // Verify Insets
      expect(AppSpacing.screenPadding.left, equals(20.0));
      expect(AppSpacing.screenPadding.right, equals(20.0));
      expect(AppSpacing.compactPadding.left, equals(16.0));
      expect(AppSpacing.spaciousPadding.left, equals(24.0));
      expect(AppSpacing.cardPadding.left, equals(16.0));
      expect(AppSpacing.cardCompactPadding.left, equals(12.0));
      expect(AppSpacing.cardSpaciousPadding.left, equals(20.0));
    });
  });
}
