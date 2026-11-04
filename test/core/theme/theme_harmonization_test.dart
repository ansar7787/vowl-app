import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/category_colors.dart';

void main() {
  group('Theme Harmonization & Design Tokens', () {
    test('Light theme has authentic scaffold background and solid White surface', () {
      final light = AppTheme.lightTheme;
      expect(light.scaffoldBackgroundColor, AppTheme.scaffoldLight);
      expect(light.brightness, Brightness.light);
      final tokens = light.extension<AppColorTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.surface, Colors.white);
      expect(tokens.textPrimary, AppColors.slate900);
      expect(tokens.border, AppColors.slate100);
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

    test('Dialog and BottomSheet themes enforce zero surface tint and authentic backgrounds', () {
      final light = AppTheme.lightTheme;
      expect(light.dialogTheme.surfaceTintColor, Colors.transparent);
      expect(light.bottomSheetTheme.surfaceTintColor, Colors.transparent);
      expect(light.dialogTheme.backgroundColor, Colors.white);
      expect(light.bottomSheetTheme.backgroundColor, Colors.white);

      final dark = AppTheme.darkTheme;
      expect(dark.dialogTheme.surfaceTintColor, Colors.transparent);
      expect(dark.bottomSheetTheme.surfaceTintColor, Colors.transparent);
      expect(dark.dialogTheme.backgroundColor, AppTheme.cardDark);
      expect(dark.bottomSheetTheme.backgroundColor, AppTheme.scaffoldDark);

      final midnight = AppTheme.midnightTheme;
      expect(midnight.dialogTheme.surfaceTintColor, Colors.transparent);
      expect(midnight.bottomSheetTheme.surfaceTintColor, Colors.transparent);
      expect(midnight.dialogTheme.backgroundColor, AppTheme.midnightCardBase);
      expect(midnight.bottomSheetTheme.backgroundColor, AppTheme.midnightCardBase);
    });
  });

  group('LevelThemeHelper AMOLED & Context Resolution', () {
    test('Every category maintains its unique identity color across all 3 theme modes', () {
      final categoryExpectedColors = {
        'speaking': CategoryColors.speaking,
        'listening': CategoryColors.listening,
        'reading': CategoryColors.reading,
        'writing': CategoryColors.writing,
        'grammar': CategoryColors.grammar,
        'vocabulary': CategoryColors.vocabulary,
        'accent': CategoryColors.accent,
        'roleplay': CategoryColors.roleplay,
        'elitemastery': CategoryColors.eliteMastery,
      };

      for (final entry in categoryExpectedColors.entries) {
        final cat = entry.key;
        final expectedColor = entry.value;

        // Verify base color
        expect(LevelThemeHelper.getCategoryBaseColor(cat), expectedColor);

        // Verify light mode preserves exact category primary color
        final lightTheme = LevelThemeHelper.getCategoryTheme(cat, isDark: false, isMidnight: false);
        expect(lightTheme.primaryColor, expectedColor);

        // Verify dark mode preserves exact category primary color
        final darkTheme = LevelThemeHelper.getCategoryTheme(cat, isDark: true, isMidnight: false);
        expect(darkTheme.primaryColor, expectedColor);

        // Verify midnight mode preserves exact category primary color
        final midnightTheme = LevelThemeHelper.getCategoryTheme(cat, isDark: true, isMidnight: true);
        expect(midnightTheme.primaryColor, expectedColor);
      }
    });

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
