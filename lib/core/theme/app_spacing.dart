import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized, production-grade spacing tokens and helpers for Vowl.
///
/// Standardizes horizontal screen padding, card interior padding, and edge insets
/// across all features, eliminating arbitrary integer literals and establishing
/// consistent visual hierarchy.
class AppSpacing {
  AppSpacing._();

  // ── Screen Horizontal Insets ──────────────────────────────────────────────

  /// Standard screen edge padding (16.w) — standardized across Home, Profile,
  /// Leaderboard, Games, Settings, and primary scroll feeds.
  static double get screen => 16.w;

  /// Compact screen padding (16.w) — used for interactive game question screens,
  /// jigsaw builders, cloze tests, roleplay branching dialogs, and translation.
  static double get compact => 16.w;

  /// Spacious screen padding (24.w) — used for Onboarding, Auth flows,
  /// and high-impact marketing modals.
  static double get spacious => 24.w;

  // ── Card Internal Padding ─────────────────────────────────────────────────

  /// Standard card interior padding (16.w) — standard content cards, bento tiles,
  /// settings rows, and primary quest question containers.
  static double get card => 16.w;

  /// Compact card interior padding (12.w) — list row tiles, option buttons,
  /// chips, tags, and trophy room badge grid cells.
  static double get cardCompact => 12.w;

  /// Spacious card interior padding (20.w) — hero spotlight cards,
  /// paywall tiers, auth form containers, and game dialogs.
  static double get cardSpacious => 20.w;

  // ── Gap Spacing Tokens ────────────────────────────────────────────────────

  /// Extra-small gap (4.w)
  static double get xs => 4.w;

  /// Small gap (8.w)
  static double get sm => 8.w;

  /// Medium gap (12.w)
  static double get md => 12.w;

  /// Base / standard gap (16.w)
  static double get base => 16.w;

  /// Large gap (20.w)
  static double get lg => 20.w;

  /// Extra-large gap (24.w)
  static double get xl => 24.w;

  /// 2X-large gap (32.w)
  static double get xxl => 32.w;

  // ── Pre-packaged EdgeInsets Helpers ───────────────────────────────────────

  /// Symmetric horizontal padding using [screen] (20.w).
  static EdgeInsets get screenPadding =>
      EdgeInsets.symmetric(horizontal: screen);

  /// Symmetric horizontal padding using [compact] (16.w).
  static EdgeInsets get compactPadding =>
      EdgeInsets.symmetric(horizontal: compact);

  /// Symmetric horizontal padding using [spacious] (24.w).
  static EdgeInsets get spaciousPadding =>
      EdgeInsets.symmetric(horizontal: spacious);

  /// Uniform card interior padding using [card] (16.w).
  static EdgeInsets get cardPadding => EdgeInsets.all(card);

  /// Uniform compact card interior padding using [cardCompact] (12.w).
  static EdgeInsets get cardCompactPadding => EdgeInsets.all(cardCompact);

  /// Uniform spacious card interior padding using [cardSpacious] (20.w).
  static EdgeInsets get cardSpaciousPadding => EdgeInsets.all(cardSpacious);

  /// Standard modal bottom sheet padding: [screen] horizontally (20.w).
  static EdgeInsets bottomSheetPadding(
    BuildContext context, {
    double? top,
    double? bottom,
  }) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(
      screen,
      top ?? 16.h,
      screen,
      bottom ?? (bottomInset > 0 ? bottomInset + 8.h : 24.h),
    );
  }

  /// Standard dialog outer inset padding: [spacious] horizontally (24.w).
  static EdgeInsets get dialogInsetPadding =>
      EdgeInsets.symmetric(horizontal: spacious, vertical: 24.h);
}
