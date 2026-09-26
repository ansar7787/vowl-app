import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorf1f5f9 = Color(0xFFF1F5F9);
}

/// Semantic color tokens for the Vowl design system.
///
/// This [ThemeExtension] provides mode-aware (light/dark/midnight) semantic
/// colors that widgets consume instead of raw hex values. Every token has a
/// clear purpose, documented below.
///
/// ### Usage
/// ```dart
/// final tokens = Theme.of(context).extension<AppColorTokens>()!;
/// Container(color: tokens.surface);
/// Text('Hello', style: TextStyle(color: tokens.textPrimary));
/// ```
///
/// ### Architecture
/// ```
/// AppColors (primitives) → AppColorTokens (semantic) → Widgets
///                       ↗
/// CategoryColors (9 cats) → Widgets (separate system)
/// ```
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    // ── Surfaces ──
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceDim,
    // ── Text ──
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    // ── Borders & Dividers ──
    required this.border,
    required this.borderSubtle,
    required this.divider,
    // ── Status: Success ──
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    // ── Status: Error ──
    required this.error,
    required this.errorContainer,
    required this.onError,
    // ── Status: Warning ──
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    // ── Status: Info ──
    required this.info,
    required this.infoContainer,
    required this.onInfo,
    // ── Game Feedback ──
    required this.gameCorrect,
    required this.gameIncorrect,
    required this.gameSelected,
    required this.gameLocked,
    // ── Rewards & Economy ──
    required this.reward,
    required this.rewardContainer,
    required this.gold,
    required this.premium,
    // ── Overlay ──
    required this.scrim,
    required this.shimmer,
    // ── Interactive ──
    required this.disabled,
  });

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Card / elevated surface background.
  final Color surface;

  /// Subtle alternate surface (e.g. input fill, section background).
  final Color surfaceVariant;

  /// Deeply recessed surface (dialog backdrop, nested containers).
  final Color surfaceDim;

  // ── Text Hierarchy ──────────────────────────────────────────────────────
  /// Primary body text — highest contrast.
  final Color textPrimary;

  /// Supporting / secondary text.
  final Color textSecondary;

  /// Captions, hints, timestamps — lowest emphasis.
  final Color textTertiary;

  /// Disabled labels.
  final Color textDisabled;

  // ── Borders & Dividers ──────────────────────────────────────────────────
  /// Default border (inputs, cards with visible edge).
  final Color border;

  /// Very subtle border (elevated cards, faint separation).
  final Color borderSubtle;

  /// Section dividers and horizontal rules.
  final Color divider;

  // ── Status: Success ─────────────────────────────────────────────────────
  /// Success accent — correct, complete, positive.
  final Color success;

  /// Success tinted background (snackbar, chip, banner).
  final Color successContainer;

  /// Text/icon on [success] surfaces.
  final Color onSuccess;

  // ── Status: Error ───────────────────────────────────────────────────────
  /// Error accent — failed, destructive, invalid.
  final Color error;

  /// Error tinted background.
  final Color errorContainer;

  /// Text/icon on [error] surfaces.
  final Color onError;

  // ── Status: Warning ─────────────────────────────────────────────────────
  /// Warning accent — caution, attention needed.
  final Color warning;

  /// Warning tinted background.
  final Color warningContainer;

  /// Text/icon on [warning] surfaces.
  final Color onWarning;

  // ── Status: Info ────────────────────────────────────────────────────────
  /// Information accent — tips, notices.
  final Color info;

  /// Info tinted background.
  final Color infoContainer;

  /// Text/icon on [info] surfaces.
  final Color onInfo;

  // ── Game Feedback ───────────────────────────────────────────────────────
  /// Correct answer highlight — replaces `Colors.greenAccent`.
  /// LCD-robust, AA-compliant, CVD-safe (with icon pairing).
  final Color gameCorrect;

  /// Incorrect answer highlight — replaces `Colors.redAccent`.
  final Color gameIncorrect;

  /// Currently selected/active option (before submission).
  final Color gameSelected;

  /// Locked/unavailable content.
  final Color gameLocked;

  // ── Rewards & Economy ───────────────────────────────────────────────────
  /// Coin/star/reward accent.
  final Color reward;

  /// Reward tinted container.
  final Color rewardContainer;

  /// Achievement gold (stars, victory).
  final Color gold;

  /// Premium features accent (Vowl Premium, elevated actions).
  final Color premium;

  // ── Overlay ─────────────────────────────────────────────────────────────
  /// Modal / scrim overlay.
  final Color scrim;

  /// Loading shimmer highlight.
  final Color shimmer;

  // ── Interactive ─────────────────────────────────────────────────────────
  /// Disabled state (buttons, fields, icons).
  final Color disabled;

  // ─────────────────────────────────────────────────────────────────────────
  // ThemeExtension overrides
  // ─────────────────────────────────────────────────────────────────────────

  @override
  AppColorTokens copyWith({
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceDim,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
    Color? divider,
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? error,
    Color? errorContainer,
    Color? onError,
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? info,
    Color? infoContainer,
    Color? onInfo,
    Color? gameCorrect,
    Color? gameIncorrect,
    Color? gameSelected,
    Color? gameLocked,
    Color? reward,
    Color? rewardContainer,
    Color? gold,
    Color? premium,
    Color? scrim,
    Color? shimmer,
    Color? disabled,
  }) {
    return AppColorTokens(
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onError: onError ?? this.onError,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfo: onInfo ?? this.onInfo,
      gameCorrect: gameCorrect ?? this.gameCorrect,
      gameIncorrect: gameIncorrect ?? this.gameIncorrect,
      gameSelected: gameSelected ?? this.gameSelected,
      gameLocked: gameLocked ?? this.gameLocked,
      reward: reward ?? this.reward,
      rewardContainer: rewardContainer ?? this.rewardContainer,
      gold: gold ?? this.gold,
      premium: premium ?? this.premium,
      scrim: scrim ?? this.scrim,
      shimmer: shimmer ?? this.shimmer,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  AppColorTokens lerp(AppColorTokens? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      gameCorrect: Color.lerp(gameCorrect, other.gameCorrect, t)!,
      gameIncorrect: Color.lerp(gameIncorrect, other.gameIncorrect, t)!,
      gameSelected: Color.lerp(gameSelected, other.gameSelected, t)!,
      gameLocked: Color.lerp(gameLocked, other.gameLocked, t)!,
      reward: Color.lerp(reward, other.reward, t)!,
      rewardContainer: Color.lerp(rewardContainer, other.rewardContainer, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pre-built token sets for each theme mode
  // ─────────────────────────────────────────────────────────────────────────

  /// Light mode semantic tokens.
  static const light = AppColorTokens(
    // Surfaces
    surface: AppColors.white,
    surfaceVariant: AppColors.slate100,
    surfaceDim: AppColors.slate50,
    // Text
    textPrimary: AppColors.slate900,
    textSecondary: AppColors.slate600,
    textTertiary: AppColors.slate400,
    textDisabled: AppColors.slate300,
    // Borders
    border: AppColors.slate200,
    borderSubtle: _LocalPalette.colorf1f5f9, // slate100 — barely visible
    divider: AppColors.slate200,
    // Success
    success: AppColors.emerald500,
    successContainer: AppColors.emerald50,
    onSuccess: AppColors.white,
    // Error
    error: AppColors.red500,
    errorContainer: AppColors.red50,
    onError: AppColors.white,
    // Warning
    warning: AppColors.amber500,
    warningContainer: AppColors.warningLight,
    onWarning: AppColors.white,
    // Info
    info: AppColors.blue500,
    infoContainer: AppColors.blue50,
    onInfo: AppColors.white,
    // Game
    gameCorrect: AppColors.gameCorrect,
    gameIncorrect: AppColors.gameIncorrect,
    gameSelected: AppColors.indigo500,
    gameLocked: AppColors.slate300,
    // Rewards
    reward: AppColors.amber500,
    rewardContainer: AppColors.amber100,
    gold: AppColors.gold,
    premium: AppColors.violet500,
    // Overlay
    scrim: Color(0x52000000), // black 32%
    shimmer: Color(0x1A6366F1), // indigo 10%
    // Interactive
    disabled: AppColors.slate300,
  );

  /// Dark mode semantic tokens.
  static const dark = AppColorTokens(
    // Surfaces
    surface: AppColors.slate800,
    surfaceVariant: AppColors.slate700,
    surfaceDim: AppColors.slate900,
    // Text
    textPrimary: AppColors.slate50,
    textSecondary: Color(0xB3FFFFFF), // white 70%
    textTertiary: Color(0x8AFFFFFF), // white 54%
    textDisabled: Color(0x61FFFFFF), // white 38%
    // Borders
    border: AppColors.slate700,
    borderSubtle: Color(0x1AFFFFFF), // white 10%
    divider: AppColors.slate700,
    // Success
    success: AppColors.emerald500,
    successContainer: AppColors.emerald950,
    onSuccess: AppColors.white,
    // Error
    error: AppColors.red500,
    errorContainer: AppColors.red900,
    onError: AppColors.white,
    // Warning
    warning: AppColors.amber500,
    warningContainer: AppColors.amber900,
    onWarning: AppColors.white,
    // Info
    info: AppColors.blue500,
    infoContainer: AppColors.blue900,
    onInfo: AppColors.white,
    // Game
    gameCorrect: AppColors.gameCorrect,
    gameIncorrect: AppColors.gameIncorrect,
    gameSelected: AppColors.indigo500,
    gameLocked: AppColors.slate600,
    // Rewards
    reward: AppColors.amber500,
    rewardContainer: AppColors.amber900,
    gold: AppColors.gold,
    premium: AppColors.violet500,
    // Overlay
    scrim: Color(0x8A000000), // black 54%
    shimmer: Color(0x338B5CF6), // violet 20%
    // Interactive
    disabled: AppColors.slate600,
  );

  /// Midnight / AMOLED mode semantic tokens.
  static const midnight = AppColorTokens(
    // Surfaces
    surface: AppColors.midnightSurface,
    surfaceVariant: AppColors.slate800,
    surfaceDim: AppColors.black,
    // Text
    textPrimary: AppColors.white,
    textSecondary: Color(0xB3FFFFFF), // white 70%
    textTertiary: Color(0x8AFFFFFF), // white 54%
    textDisabled: Color(0x61FFFFFF), // white 38%
    // Borders
    border: AppColors.slate800,
    borderSubtle: Color(0x1AFFFFFF), // white 10%
    divider: AppColors.slate800,
    // Success
    success: AppColors.emerald500,
    successContainer: AppColors.emerald950,
    onSuccess: AppColors.white,
    // Error
    error: AppColors.red500,
    errorContainer: AppColors.red900,
    onError: AppColors.white,
    // Warning
    warning: AppColors.amber500,
    warningContainer: AppColors.amber900,
    onWarning: AppColors.white,
    // Info
    info: AppColors.blue500,
    infoContainer: AppColors.blue900,
    onInfo: AppColors.white,
    // Game
    gameCorrect: AppColors.gameCorrect,
    gameIncorrect: AppColors.gameIncorrect,
    gameSelected: AppColors.indigo500,
    gameLocked: AppColors.slate600,
    // Rewards
    reward: AppColors.amber500,
    rewardContainer: AppColors.amber900,
    gold: AppColors.gold,
    premium: AppColors.violet500,
    // Overlay
    scrim: Color(0xCC000000), // black 80%
    shimmer: Color(0x338B5CF6), // violet 20%
    // Interactive
    disabled: AppColors.slate600,
  );
}
