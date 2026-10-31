import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_theme.dart';

void main() {
  group('Theme Harmonization & Design Tokens', () {
    test('Light theme has Slate-50 scaffold background and solid White surface', () {
      final light = AppTheme.lightTheme;
      expect(light.scaffoldBackgroundColor, AppColors.slate50);
      expect(light.brightness, Brightness.light);
      final tokens = light.extension<AppColorTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.surface, Colors.white);
      expect(tokens.textPrimary, AppColors.slate900);
      expect(tokens.border, AppColors.slate200);
    });

    test('Dark theme has Slate-900 scaffold background and Slate-800 surface', () {
      final dark = AppTheme.darkTheme;
      expect(dark.scaffoldBackgroundColor, AppColors.slate900);
      expect(dark.brightness, Brightness.dark);
      final tokens = dark.extension<AppColorTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.surface, AppColors.slate800);
      expect(tokens.textPrimary, AppColors.slate50);
    });

    test('Midnight theme has Pure Black AMOLED background and MidnightSurface', () {
      final midnight = AppTheme.midnightTheme;
      expect(midnight.scaffoldBackgroundColor, Colors.black);
      expect(midnight.brightness, Brightness.dark);
      final tokens = midnight.extension<AppColorTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.surface, AppColors.midnightSurface);
      expect(tokens.textPrimary, Colors.white);
    });
  });

  group('LevelThemeHelper AMOLED & Context Resolution', () {
    test('LevelThemeHelper produces pure black bgTop and bgBottom in Midnight mode', () {
      final categories = [
        'accent',
        'grammar',
        'listening',
        'reading',
        'roleplay',
        'speaking',
        'vocabulary',
        'writing',
      ];

      for (final cat in categories) {
        final theme = LevelThemeHelper.getTheme(
          cat,
          isDark: true,
          isMidnight: true,
          level: 1,
        );
        expect(theme.backgroundColors.first, Colors.black,
            reason: '$cat bgTop must be pure black in midnight');
        expect(theme.backgroundColors.last, Colors.black,
            reason: '$cat bgBottom must be pure black in midnight');
      }
    });

    testWidgets('LevelThemeHelper.of correctly adapts across Light, Dark, and Midnight', (tester) async {
      late ThemeResult resolvedTheme;

      Widget buildHarness(ThemeData themeData) {
        return MaterialApp(
          key: ValueKey(themeData.scaffoldBackgroundColor),
          theme: themeData,
          home: Builder(
            builder: (context) {
              resolvedTheme = LevelThemeHelper.of(context, 'accent', level: 1);
              return const SizedBox.shrink();
            },
          ),
        );
      }

      // 1. Light Mode
      await tester.pumpWidget(buildHarness(AppTheme.lightTheme));
      expect(resolvedTheme.backgroundColors.last, isNot(Colors.black));

      // 2. Dark Mode
      await tester.pumpWidget(buildHarness(AppTheme.darkTheme));
      expect(resolvedTheme.backgroundColors.last, AppColors.slate900);

      // 3. Midnight Mode
      await tester.pumpWidget(buildHarness(AppTheme.midnightTheme));
      expect(resolvedTheme.backgroundColors.first, Colors.black);
      expect(resolvedTheme.backgroundColors.last, Colors.black);
    });

    testWidgets('AppThemeContextExtension getters function accurately', (tester) async {
      late bool isDarkVal;
      late bool isMidnightVal;
      late AppColorTokens tokensVal;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.midnightTheme,
          home: Builder(
            builder: (context) {
              isDarkVal = context.isDark;
              isMidnightVal = context.isMidnight;
              tokensVal = context.tokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(isDarkVal, isTrue);
      expect(isMidnightVal, isTrue);
      expect(tokensVal.surface, AppColors.midnightSurface);
    });
  });
}
