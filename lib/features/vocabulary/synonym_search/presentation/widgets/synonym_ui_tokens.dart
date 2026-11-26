import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_dimensions.dart';
import 'package:vowl/core/theme/app_spacing.dart';

/// Shared typography, radius, padding, and surface tokens for Synonym Search.
///
/// Aligns Learn, Practice, and Mastery screens to Vowl's [AppDimensions] and
/// [AppSpacing] standards with a balanced weight hierarchy (regular prose,
/// semi-bold controls, bold display words).
class SynonymUiTokens {
  SynonymUiTokens._();

  // ── Radii & Padding ───────────────────────────────────────────────────────

  static double get cardRadius => AppDimensions.radiusLg.r; // 16.r
  static double get controlRadius => AppDimensions.radiusMd.r; // 12.r
  static double get badgeRadius => AppDimensions.radiusSm.r; // 8.r

  static EdgeInsets get cardPadding => EdgeInsets.all(AppSpacing.card); // 16.w
  static EdgeInsets get innerPanelPadding => EdgeInsets.all(14.w);
  static EdgeInsets get pillPadding =>
      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h);
  static EdgeInsets get badgePadding =>
      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h);

  // ── Typography Scale ──────────────────────────────────────────────────────

  static TextStyle displayWord({
    required Color color,
    FontWeight fontWeight = FontWeight.w700,
  }) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 20.sp,
    fontWeight: fontWeight,
    color: color,
    height: 1.25,
  );

  static TextStyle sectionHeading({required Color color}) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.35,
  );

  static TextStyle sentenceBody({required Color color}) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.45,
  );

  static TextStyle interactiveWord({
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 15.sp,
    fontWeight: fontWeight,
    color: color,
    height: 1.3,
  );

  static TextStyle supportBody({
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 13.5.sp,
    fontWeight: fontWeight,
    color: color,
    height: 1.42,
  );

  static TextStyle controlLabel({
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 13.sp,
    fontWeight: fontWeight,
    color: color,
    height: 1.25,
  );

  static TextStyle badgeLabel({
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 12.sp,
    fontWeight: fontWeight,
    color: color,
    height: 1.2,
  );

  // ── Surface Helpers ───────────────────────────────────────────────────────

  static Color cardSurface(bool isDark) =>
      isDark ? AppColors.slate800.withValues(alpha: 0.92) : Colors.white;

  static Color primaryText(bool isDark) =>
      isDark ? AppColors.slate50 : AppColors.slate900;

  static Color secondaryText(bool isDark) =>
      isDark ? AppColors.slate200 : AppColors.slate700;

  static Color mutedText(bool isDark) =>
      isDark ? AppColors.slate300 : AppColors.slate600;

  static Color subtleBorder(bool isDark) =>
      isDark ? AppColors.slate700 : AppColors.slate200;

  static List<BoxShadow> softCardShadow(bool isDark, {Color? tint}) => [
    BoxShadow(
      color: (tint ?? Colors.black).withValues(alpha: isDark ? 0.18 : 0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}
