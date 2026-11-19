import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/category_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Universal, 120 FPS-optimized game HUD shared across all 100 mini-games in VOWL.
///
/// Features a real-world AAA 3-Zone Anchor layout:
/// - **Zone 1 (Left Navigation Anchor):**
///   - Tactile 3D Pause Squircle Button with dual embossed rounded pill bars (36x36dp, 12r radius).
/// - **Zone 2 (Center Progression Anchor - Fluid Expanded):**
///   - Fluid, centered progress track taking up the exact remaining width without lopsided mass.
///   - Top meta row: Category-colored level indicator ("LEVEL 14") + live percentage ("65%").
///   - Bottom bar: High-precision 6dp solid progress indicator.
/// - **Zone 3 (Right Player Status & Actions Anchor):**
///   - Unified Vector Hearts Capsule (36dp height, 12r radius) with live remaining life pips.
///   - Cohesive Smart Hint Capsule (36dp height, 12r radius) with 0ms optimistic deduction.
///   - Tactile Briefing Squircle Tile (36x36dp, 12r radius, ℹ️ icon) for instant on-screen rule access.
///
/// Theme Adaptability:
/// - High contrast across Light Mode, Dark Mode, and Midnight AMOLED mode.
class VowlUniversalGameHeader extends StatelessWidget {
  /// The active level number (1-based).
  final int level;

  /// The game category identifier (e.g. 'grammar', 'vocabulary', 'reading').
  final String category;

  /// Completion progress fraction (0.0 to 1.0).
  final double progress;

  /// Remaining user hearts (0 to 3).
  final int lives;

  /// Optional notifier for fine-grained progress updates without parent rebuilds.
  final ValueListenable<double>? progressNotifier;

  /// Optional notifier for fine-grained lives updates without parent rebuilds.
  final ValueListenable<int>? livesNotifier;

  /// Optional pedagogical hint text for the current quest.
  final String? hintText;

  /// Whether the current quest's hint has already been revealed/used.
  final bool isHintUsedOnCurrentQuest;

  /// Callback executed when tapping the Pause button.
  final VoidCallback onPause;

  /// Whether the briefing (ℹ️) button should be displayed in the top row.
  /// Defaults to true for instant on-screen access to level rules and objectives.
  final bool showBriefing;

  /// Optional callback executed when tapping the Briefing (ℹ️) button.
  /// If omitted, automatically resolves from [GameBriefingScope] if present in context.
  final VoidCallback? onBriefing;

  /// Callback executed when activating the Hint (💡) action.
  final VoidCallback onHint;

  /// Whether the hint button should be shown at all. Set to false for games without hints.
  final bool showHint;

  /// Whether the hint action is currently enabled.
  final bool isHintEnabled;

  /// Optional phase badge label (e.g. '⚔️ TEST' or 'PRACTICE').
  final String? phaseBadge;

  /// Optional custom color for the phase badge. Defaults to emerald.
  final Color? phaseBadgeColor;

  const VowlUniversalGameHeader({
    super.key,
    required this.level,
    required this.category,
    this.phaseBadge = '🏆 MASTERY',
    this.phaseBadgeColor = AppColors.emerald500,
    this.progress = 0.0,
    this.lives = 3,
    this.progressNotifier,
    this.livesNotifier,
    this.hintText,
    this.isHintUsedOnCurrentQuest = false,
    required this.onPause,
    this.onBriefing,
    required this.onHint,
    this.showHint = true,
    this.showBriefing = true,
    this.isHintEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final solidColor = CategoryColors.forCategory(category);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBriefing = onBriefing ??
        (GameBriefingScope.of(context) != null
            ? () => GameBriefingScope.show(context)
            : null);

    return RepaintBoundary(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── ZONE 1: Left Navigation Anchor (36x36dp Squircle) ─────────
              _buildTactilePauseButton(context, isDark),

              // ── ZONE 2: Center Progression Anchor (Fluid Expanded) ───────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Level Label & Dynamic Percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    context.tr(
                                      'game_progress.level_label',
                                      fallback: 'LEVEL $level',
                                      args: ['$level'],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textScaler: const TextScaler.linear(1.0),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : AppColors.slate900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                if (phaseBadge != null) ...[
                                  SizedBox(width: 5.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 1.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (phaseBadgeColor ?? AppColors.rose500)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: (phaseBadgeColor ?? AppColors.rose500)
                                            .withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      phaseBadge!,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                        color: phaseBadgeColor ?? AppColors.rose500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          _buildProgressPercentage(context, isDark, solidColor),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      // Smooth High-Precision Solid Progress Bar
                      _buildProgressBar(context, solidColor, isDark, isRtl),
                    ],
                  ),
                ),
              ),

              // ── ZONE 3: Right Player Status & Actions Anchor ─────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Vector Hearts Trio Capsule (36dp Height, 12r Radius)
                  _buildLivesCluster(context, isDark),

                  // 2. Cohesive Smart Hint Capsule (36dp Height, 12r Radius)
                  if (showHint) ...[
                    SizedBox(width: 5.w),
                    _buildUnifiedHintCapsule(context, isDark),
                  ],

                  // 3. Tactile Briefing Squircle Tile (36x36dp, 12r Radius)
                  if (showBriefing && effectiveBriefing != null) ...[
                    SizedBox(width: 5.w),
                    _buildTactileBriefingTile(context, effectiveBriefing, solidColor, isDark),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a tactile, 3D-styled pause button with dual rounded vertical pill bars.
  /// Eliminates the plain flat 2-line look and provides high contrast across all modes.
  Widget _buildTactilePauseButton(BuildContext context, bool isDark) {
    final pauseBarColor = isDark ? Colors.white : AppColors.slate900;

    return Semantics(
      button: true,
      label: context.tr('common.pause', fallback: 'Pause Game'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPause,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 3.5.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: pauseBarColor,
                      borderRadius: BorderRadius.circular(2.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 3.5.w),
                  Container(
                    width: 3.5.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: pauseBarColor,
                      borderRadius: BorderRadius.circular(2.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the dynamic progress percentage indicator.
  Widget _buildProgressPercentage(BuildContext context, bool isDark, Color solidColor) {
    final style = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 10.sp,
      fontWeight: FontWeight.w800,
      color: isDark ? AppColors.slate400 : AppColors.slate600,
    );

    if (progressNotifier != null) {
      return ValueListenableBuilder<double>(
        valueListenable: progressNotifier!,
        builder: (context, p, _) => Text(
          '${(p.clamp(0.0, 1.0) * 100).toInt()}%',
          style: style,
          textScaler: const TextScaler.linear(1.0),
        ),
      );
    }
    return Text(
      '${(progress.clamp(0.0, 1.0) * 100).toInt()}%',
      style: style,
      textScaler: const TextScaler.linear(1.0),
    );
  }

  /// Builds the tactile squircle briefing (ℹ️) button.
  Widget _buildTactileBriefingTile(
    BuildContext context,
    VoidCallback onTap,
    Color solidColor,
    bool isDark,
  ) {
    return Semantics(
      button: true,
      label: context.tr('games.briefing_tooltip', fallback: 'Level Briefing'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: solidColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: solidColor.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.info_outline_rounded,
                color: solidColor,
                size: 18.r,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the unified hint capsule with zero visual clutter and transaction-safe global deduction.
  Widget _buildUnifiedHintCapsule(BuildContext context, bool isDark) {
    return QuestHintButton(
      used: isHintUsedOnCurrentQuest,
      primaryColor: AppColors.amber500,
      hintText: hintText,
      onTap: onHint,
      isHintEnabled: isHintEnabled,
    );
  }

  Widget _buildLivesCluster(BuildContext context, bool isDark) {
    if (livesNotifier != null) {
      return ValueListenableBuilder<int>(
        valueListenable: livesNotifier!,
        builder: (context, currentLives, _) => _renderHearts(context, currentLives, isDark),
      );
    }
    return _renderHearts(context, lives, isDark);
  }

  Widget _renderHearts(BuildContext context, int count, bool isDark) {
    final clampedCount = count.clamp(0, 3);
    final hasLives = clampedCount > 0;

    return Semantics(
      label: context.tr(
        'game_progress.lives_label',
        fallback: '$count lives remaining',
        args: ['$count'],
      ),
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasLives
              ? AppColors.rose500.withValues(alpha: isDark ? 0.16 : 0.10)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasLives
                ? AppColors.rose500.withValues(alpha: isDark ? 0.40 : 0.28)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            width: 1.2,
          ),
          boxShadow: [
            if (hasLives)
              BoxShadow(
                color: AppColors.rose500.withValues(alpha: isDark ? 0.15 : 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (index) {
            final isAlive = index < clampedCount;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: AnimatedScale(
                scale: isAlive ? 1.0 : 0.82,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: isAlive ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 15.5.r,
                    color: isAlive
                        ? AppColors.rose500
                        : (isDark
                            ? AppColors.slate600.withValues(alpha: 0.6)
                            : AppColors.slate400.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, Color solidColor, bool isDark, bool isRtl) {
    if (progressNotifier != null) {
      return ValueListenableBuilder<double>(
        valueListenable: progressNotifier!,
        builder: (context, currentProgress, _) => _renderProgressBarTrack(currentProgress, solidColor, isDark, isRtl),
      );
    }
    return _renderProgressBarTrack(progress, solidColor, isDark, isRtl);
  }

  Widget _renderProgressBarTrack(double currentProgress, Color solidColor, bool isDark, bool isRtl) {
    final clamped = currentProgress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3.r),
      child: SizedBox(
        width: double.infinity,
        height: 6.h,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              widthFactor: clamped,
              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: solidColor,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
