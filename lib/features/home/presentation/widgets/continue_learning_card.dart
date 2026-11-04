import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Primary action & learning momentum card on the home screen (The Apex Momentum Cockpit).
///
/// Directs learners to their next curriculum category using an intelligent
/// two-tier algorithm ("True Resume" from recent activity, falling back to
/// "Skill Balancing" across core competencies).
///
/// Features:
/// 1. **Compact 1-Row Header**: Category pill on left, habit urgency badge on right. Zero badge stacking.
/// 2. **Punchy 1-Line Subtitle**: Short, motivating phrasing that fits on 1 line across small, medium, and large screens.
/// 3. **Non-glaring Cockpit Aesthetics**: Sophisticated obsidian/slate elevation in dark mode, crisp porcelain in light mode.
/// 4. **Solid Category Color**: Progress bar uses the pure, authentic category color (zero gradients).
/// 5. **Zero Overflow & No Ellipses**: Balanced paddings with AutoSizeText dynamic scaling on every phone form factor.
class ContinueLearningCard extends StatefulWidget {
  /// Current authenticated [user] entity. Null in loading or shimmer mode.
  final UserEntity? user;

  /// Whether the card is currently fetching data or resolving state.
  final bool isLoading;

  /// Creates a [ContinueLearningCard] for [user].
  const ContinueLearningCard({
    super.key,
    required UserEntity this.user,
    this.isLoading = false,
  });

  /// Shimmer placeholder constructor for pre-load and loading states.
  const ContinueLearningCard.shimmer({super.key})
    : user = null,
      isLoading = true;

  @override
  State<ContinueLearningCard> createState() => _ContinueLearningCardState();
}

class _ContinueLearningCardState extends State<ContinueLearningCard> {
  /// Canonical learning journey order (aligned with BentoArena).
  static const List<QuestType> _journeyOrder = [
    QuestType.vocabulary,
    QuestType.listening,
    QuestType.reading,
    QuestType.grammar,
    QuestType.writing,
    QuestType.speaking,
    QuestType.accent,
    QuestType.roleplay,
    QuestType.eliteMastery,
  ];

  // ── Cached State ────────────────────────────────────────────────────────
  QuestType _nextType = QuestType.vocabulary;
  int _cleared = 0;
  int _max = 0;

  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null && !widget.isLoading) {
      _computeState();
    }
  }

  @override
  void didUpdateWidget(covariant ContinueLearningCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != null && !widget.isLoading) {
      if (oldWidget.user != widget.user ||
          oldWidget.isLoading != widget.isLoading) {
        _computeState();
      }
    }
  }

  void _computeState() {
    final user = widget.user;
    if (user == null) return;
    _nextType = _resolveNextCategory(user);
    _cleared = user.getTotalCategoryLevelsCleared(_nextType);
    _max = user.getMaxCategoryLevels(_nextType);
  }

  /// Implements a hybrid algorithm for optimal learning momentum:
  /// 1. "True Resume": Inspects `recentActivities` for the exact unfinished quest category.
  /// 2. "Skill Balancing": Falls back to the available category with the lowest progress.
  QuestType _resolveNextCategory(UserEntity user) {
    if (user.totalLevelsCompleted == 0) return QuestType.vocabulary;

    // 1. "True Resume": Check last played quest.
    for (final activity in user.recentActivities) {
      if (activity['type'] == 'quest') {
        final gameTypeStr = activity['gameType'] as String?;
        if (gameTypeStr != null) {
          final subtype = GameSubtype.values.firstWhereOrNull(
            (s) => s.name == gameTypeStr,
          );
          if (subtype != null) {
            final type = subtype.category;
            final cleared = user.getTotalCategoryLevelsCleared(type);
            final max = user.getMaxCategoryLevels(type);
            if (max > 0 && cleared < max) {
              return type;
            }
          }
        }
      }
    }

    // 2. "Skill Balancing": Lowest progress category fallback.
    QuestType recommendedType = _journeyOrder.first;
    int lowestCleared = 999999;

    for (final type in _journeyOrder) {
      final cleared = user.getTotalCategoryLevelsCleared(type);
      final max = user.getMaxCategoryLevels(type);

      if (max > 0 && cleared < lowestCleared) {
        lowestCleared = cleared;
        recommendedType = type;
      }
    }

    return recommendedType;
  }

  /// Formats category type into a readable title string.
  String _formatCategoryTitle(QuestType type) {
    switch (type) {
      case QuestType.vocabulary:
        return 'Vocabulary';
      case QuestType.listening:
        return 'Listening';
      case QuestType.reading:
        return 'Reading';
      case QuestType.grammar:
        return 'Grammar';
      case QuestType.writing:
        return 'Writing';
      case QuestType.speaking:
        return 'Speaking';
      case QuestType.accent:
        return 'Accent';
      case QuestType.roleplay:
        return 'Roleplay';
      case QuestType.eliteMastery:
        return 'Mastery';
    }
  }

  /// Returns achievable milestone chunk targets (10, 25, 50, 100).
  ({int baseTarget, int target}) _getNextMilestone() {
    int baseTarget = 0;
    int target = 0;

    if (_cleared < 50) {
      baseTarget = (_cleared ~/ 10) * 10;
      target = baseTarget + 10;
    } else if (_cleared < 200) {
      baseTarget = (_cleared ~/ 25) * 25;
      target = baseTarget + 25;
    } else if (_cleared < 1000) {
      baseTarget = (_cleared ~/ 50) * 50;
      target = baseTarget + 50;
    } else {
      baseTarget = (_cleared ~/ 100) * 100;
      target = baseTarget + 100;
    }

    if (target > _max && _max > 0) target = _max;

    return (baseTarget: baseTarget, target: target);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.user == null) {
      return _buildShimmer(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final user = widget.user!;
    final color = GameHelper.getQuestTypeColor(_nextType);
    final icon = GameHelper.getIconForCategory(_nextType);
    final isNewUser = user.totalLevelsCompleted == 0;
    final isTodayActive = user.hasCompletedDailyGoal;
    final currentStreak = user.currentStreak;
    final categoryDisplayName = _formatCategoryTitle(_nextType);

    final categoryLabel = _nextType.name.toUpperCase().replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (m) => ' ',
    );

    final title = isNewUser
        ? context.tr('home.start_your_journey', fallback: 'Start Your Journey')
        : context.tr('home.continue_learning', fallback: 'Continue Learning');

    final milestone = _getNextMilestone();
    final chunkSpan = milestone.target - milestone.baseTarget;
    final progressInChunk = _cleared - milestone.baseTarget;

    final milestoneProgress = chunkSpan > 0
        ? (progressInChunk / chunkSpan).clamp(0.0, 1.0)
        : (_cleared >= _max && _max > 0 ? 1.0 : 0.0);

    final remaining = milestone.target - _cleared;

    // ── Concise Status Badges (Fits horizontally without squeezing) ──
    final String missionBadgeText;
    final Color missionBadgeColor;
    final IconData missionBadgeIcon;

    if (isNewUser) {
      missionBadgeColor = color;
      missionBadgeIcon = Icons.explore_rounded;
      missionBadgeText = context.tr(
        'home.mission_day_one',
        fallback: 'DAY 1 JOURNEY',
      );
    } else if (!isTodayActive) {
      missionBadgeColor = AppColors.amber500;
      if (currentStreak > 0) {
        missionBadgeIcon = Icons.local_fire_department_rounded;
        missionBadgeText = context.tr(
          'home.mission_daily_goal',
          fallback: 'DAILY GOAL',
        );
      } else {
        missionBadgeIcon = Icons.bolt_rounded;
        missionBadgeText = context.tr(
          'home.mission_start_streak_badge',
          fallback: 'DAILY MISSION',
        );
      }
    } else {
      missionBadgeColor = AppColors.emerald500;
      missionBadgeIcon = Icons.check_circle_rounded;
      missionBadgeText = context.tr(
        'home.mission_streak_secured_badge',
        fallback: 'STREAK ACTIVE',
      );
    }

    // ── Crisp, Punchy 1-Line Subtitle (Fits smoothly on all screen widths) ──
    final String subtitle;
    if (!isTodayActive && currentStreak > 0) {
      subtitle = context.tr(
        'home.protect_streak_subtitle_short',
        fallback: '1 level to protect your {}d streak',
        args: [currentStreak.toString()],
      );
    } else if (isNewUser) {
      subtitle = context.tr(
        'home.first_step_in_category_short',
        fallback: 'First step in {}',
        args: [categoryDisplayName],
      );
    } else if (remaining > 1) {
      subtitle = context.tr(
        'home.levels_to_reach_milestone_short',
        fallback: '$remaining levels to reach next goal',
        args: [remaining.toString()],
      );
    } else if (remaining == 1) {
      subtitle = context.tr(
        'home.level_to_reach_milestone_short',
        fallback: '1 level to reach next goal',
      );
    } else {
      subtitle = context.tr(
        'home.milestone_completed_short',
        fallback: 'Goal completed • Keep mastering',
      );
    }

    final String ctaLabel;

    if (!isTodayActive && currentStreak > 0) {
      ctaLabel = context.tr(
        'home.secure_streak_btn',
        fallback: 'Secure',
      );
    } else if (isNewUser) {
      ctaLabel = context.tr(
        'home.start',
        fallback: 'Start',
      );
    } else {
      ctaLabel = context.tr(
        'home.resume',
        fallback: 'Resume',
      );
    }

    final semanticLabel = isNewUser
        ? '$missionBadgeText. $title. $categoryDisplayName.'
        : '$missionBadgeText. $title. $categoryDisplayName. $_cleared out of ${milestone.target} levels cleared.';

    final card = Semantics(
      button: true,
      label: semanticLabel,
      child: ScaleButton(
        onTap: () {
          try {
            di.sl<HapticService>().selection();
            if (isTodayActive && di.sl.isRegistered<SoundService>()) {
              di.sl<SoundService>().playStreakFlameIgnite();
            }
          } catch (_) {}
          context.push(
            '${AppRouter.categoryGamesRoute}?category=${Uri.encodeQueryComponent(_nextType.name)}',
          );
        },
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isMidnight
                    ? AppColors.midnightSurface
                    : (isDark ? const Color(0xFF131A29) : Colors.white),
                gradient: isDark
                    ? LinearGradient(
                        colors: isMidnight
                            ? const [Color(0xFF0B0F19), Color(0xFF060910)]
                            : const [Color(0xFF131A29), Color(0xFF0D1320)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isMidnight
                      ? Colors.white.withValues(alpha: 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate100),
                  width: 1.0,
                ),
              ),
              child: Stack(
                children: [
                  // ── Subtle Accent Border Glow on Left Edge (Flush with card border) ──
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: !isTodayActive ? 4.r : 3.5.r,
                      decoration: BoxDecoration(
                        color: !isTodayActive ? color : AppColors.emerald500,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          bottomLeft: Radius.circular(24.r),
                        ),
                      ),
                    ),
                  ),

                  // ── Elegant Watermark Glyph (Vertically centered in open right-side space) ──
                  Positioned(
                    right: -10.r,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: const Alignment(1.0, -0.12),
                      child: IgnorePointer(
                        child: Icon(
                          icon,
                          size: 92.r,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.055)
                              : color.withValues(alpha: 0.075),
                        ),
                      ),
                    ),
                  ),

                  // ── Main Cockpit Content with Calibrated Padding ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Top Header Row: Category Pill (Left) & Mission Status (Right) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Category Pill
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(
                                    alpha: isDark ? 0.14 : 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(100.r),
                                  border: Border.all(
                                    color: color.withValues(
                                      alpha: isDark ? 0.28 : 0.20,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, color: color, size: 13.5.r),
                                    SizedBox(width: 5.w),
                                    Flexible(
                                      child: AutoSizeText(
                                        categoryLabel,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        minFontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),

                            // Habit Mission Status Pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: missionBadgeColor.withValues(
                                  alpha: isDark ? 0.16 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(100.r),
                                border: Border.all(
                                  color: missionBadgeColor.withValues(
                                    alpha: isDark ? 0.32 : 0.22,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    missionBadgeIcon,
                                    color: missionBadgeColor,
                                    size: 13.r,
                                  ),
                                  SizedBox(width: 4.5.w),
                                  Text(
                                    missionBadgeText,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: missionBadgeColor,
                                      letterSpacing: 0.4,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate900,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),

                        // Contextual Subtitle (Crisp & punchy, fits on 1 line across phones)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.slate300
                                : AppColors.slate600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          softWrap: true,
                        ),
                        SizedBox(height: 12.h),

                        // ── Inset Cockpit Bottom Tray ────────────────────
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 9.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.035)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.slate100,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Progress bar & label
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Flexible(
                                          child: AutoSizeText(
                                            context.tr(
                                              'home.milestone_progress',
                                              fallback: 'Milestone Progress',
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 11.5.sp,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.slate400
                                                  : AppColors.slate600,
                                            ),
                                            maxLines: 1,
                                            minFontSize: 9,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          '$_cleared / ${milestone.target}',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),

                                    // Milestone progress bar with SOLID category color
                                    RepaintBoundary(
                                      child: Stack(
                                        children: [
                                          // Track
                                          Container(
                                            height: 6.h,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : AppColors.slate200,
                                              borderRadius:
                                                  BorderRadius.circular(100.r),
                                            ),
                                          ),
                                          // Fill: Solid authentic category color (NO gradient)
                                          FractionallySizedBox(
                                            widthFactor:
                                                milestoneProgress.clamp(
                                              isNewUser ? 0.02 : 0.04,
                                              1.0,
                                            ),
                                            child: Container(
                                              height: 6.h,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        100.r),
                                              ),
                                            ).animateIf(
                                              context,
                                              (w) => w.animate().scaleX(
                                                    begin: 0,
                                                    end: 1,
                                                    duration: 800.ms,
                                                    curve: Curves.easeOutQuart,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),

                              // Tactile Primary Button
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(
                                        alpha: !isTodayActive ? 0.45 : 0.30,
                                      ),
                                      blurRadius: !isTodayActive ? 10 : 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ctaLabel,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 16.r,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

    // Entrance animation: fires once upon mount
    if (!_hasAnimated) {
      _hasAnimated = true;
      if (VowlMotion.shouldReduceMotion(context)) return card;
      return card
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
    }
    return card;
  }

  /// Shimmer skeleton precisely matching the compact proportions.
  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final baseBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.slate100);

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: baseBg,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Category pill on left + status badge on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoading.rounded(
                    width: 95.w,
                    height: 22.h,
                    borderRadius: 100.r,
                  ),
                  ShimmerLoading.rounded(
                    width: 85.w,
                    height: 22.h,
                    borderRadius: 100.r,
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Title shimmer
              ShimmerLoading.rounded(
                width: 150.w,
                height: 20.h,
                borderRadius: 6.r,
              ),
              SizedBox(height: 3.h),

              // Subtitle shimmer
              ShimmerLoading.rounded(
                width: 200.w,
                height: 13.h,
                borderRadius: 4.r,
              ),
              SizedBox(height: 12.h),

              // Inset tray shimmer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShimmerLoading.rounded(
                                width: 85.w,
                                height: 12.h,
                                borderRadius: 4.r,
                              ),
                              ShimmerLoading.rounded(
                                width: 28.w,
                                height: 12.h,
                                borderRadius: 4.r,
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          ShimmerLoading.rounded(
                            width: double.infinity,
                            height: 6.h,
                            borderRadius: 100.r,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    ShimmerLoading.rounded(
                      width: 68.w,
                      height: 30.h,
                      borderRadius: 12.r,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
