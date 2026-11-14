import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/category_colors.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';

/// Universal, 120 FPS-optimized game HUD shared across all 100 mini-games in VOWL.
///
/// Features a two-tier layout:
/// - **Tier 1 (Tactile Controls & Metrics):**
///   - Left: Tactile 3D Pause Squircle Button with dual embossed rounded pill bars.
///   - Center-Left: Solid level badge tinted with official [CategoryColors].
///   - Center-Right: 3 vector hearts cluster with micro-scale animations on hit.
///   - Right: Briefing (ℹ️) Squircle Tile and Unified Cohesive Hint (💡 / 🎬) Capsule.
/// - **Tier 2 (Progress Tracker):**
///   - Full-width, 6dp solid progress indicator rendered without multi-color gradients.
///
/// Smart Hint System & Global Economy:
/// - Connects to global [AuthBloc] and [EconomyBloc].
/// - 0ms Optimistic UI deduction + SharedPreferences caching ([AuthHintConsumedOptimistic]).
/// - Transaction-safe Firestore deduction ([EconomyConsumeHintRequested]) to eliminate refresh loopholes.
/// - Free re-review of hints already unlocked on the current question.
/// - **Premium User:** Unlimited hints in a clean tactile amber tile ([ 💡 ]).
/// - **Free User with Hints:** Unified pill displaying icon + count side-by-side ([ 💡 2 ]).
/// - **Free User with 0 Hints:** Seamless Rewarded Ad Capsule ([ 🎬 +1 ]),
///   tapping opens [GameDialogHelper.showHintAdDialog].
///
/// Theme Adaptability:
/// - Full contrast support for Light Mode, Dark Mode, and Midnight AMOLED mode.
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
  /// Defaults to false to provide an uncluttered 4-control header (Pause, Level, Hearts, Hint).
  /// Briefing is readily accessible in the Pause bottom sheet.
  final bool showBriefing;

  /// Optional callback executed when tapping the Briefing (ℹ️) button.
  final VoidCallback? onBriefing;

  /// Callback executed when activating the Hint (💡) action.
  final VoidCallback onHint;

  /// Whether the hint button should be shown at all. Set to false for games without hints.
  final bool showHint;

  /// Whether the hint action is currently enabled.
  final bool isHintEnabled;

  const VowlUniversalGameHeader({
    super.key,
    required this.level,
    required this.category,
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
    this.showBriefing = false,
    this.isHintEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final solidColor = CategoryColors.forCategory(category);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── TIER 1: Standardized Controls, Metrics, and Lives ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Tactile Pause Button (Standard 36x36dp Squircle with Embossed Pill Bars)
                  _buildTactilePauseButton(context, isDark),

                  // 2. Solid Level Badge (Standard 36dp Height, Official Category Color)
                  Container(
                    height: 36.h,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: solidColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      context.tr(
                        'game_progress.level_label',
                        fallback: 'LEVEL $level',
                        args: ['$level'],
                      ),
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // 3. Vector Hearts Cluster (Standard 36dp Height, 3 Lives)
                  _buildLivesCluster(context, isDark),

                  // 4. Utility Actions: Optional Briefing (ℹ️) & Smart Hint (💡)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tactile Briefing Squircle Tile (Standard 36x36dp, shown only when showBriefing: true)
                      if (showBriefing && onBriefing != null) ...[
                        Semantics(
                          button: true,
                          label: context.tr('games.briefing_tooltip', fallback: 'Level Briefing'),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onBriefing,
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
                        ),
                        if (showHint) SizedBox(width: 5.w),
                      ],
                      // Cohesive Unified Smart Hint Capsule (Standard 36dp Height)
                      if (showHint) _buildUnifiedHintCapsule(context, isDark),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 6.h),

              // ── TIER 2: Full-Width Solid Progress Bar ───────────────────
              _buildProgressBar(context, solidColor, isDark, isRtl),
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
                    : AppColors.slate300.withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 3,
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
    return Semantics(
      label: context.tr(
        'game_progress.lives_label',
        fallback: '$count lives remaining',
        args: ['$count'],
      ),
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (index) {
            final isAlive = index < count;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: AnimatedScale(
                scale: isAlive ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16.r,
                  color: isAlive
                      ? AppColors.rose500
                      : (isDark
                          ? AppColors.slate600.withValues(alpha: 0.4)
                          : AppColors.slate400.withValues(alpha: 0.4)),
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
      borderRadius: BorderRadius.circular(2.5.r),
      child: SizedBox(
        width: double.infinity,
        height: 5.h,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              widthFactor: clamped,
              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                color: solidColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
