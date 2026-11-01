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
/// 1. **Solid Category Color**: Progress bar uses the pure, authentic category color (zero gradients).
/// 2. **100% Real Progression Data**: Dynamically calculates cleared levels, milestone targets, and remaining steps.
/// 3. **Non-glaring Cockpit Aesthetics**: Sophisticated obsidian/slate elevation in dark mode, crisp porcelain in light mode.
/// 4. **Tactile Spring Navigation**: Seamlessly routes to the Category Games Hub via [ScaleButton].
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
    final user = widget.user!;
    final color = GameHelper.getQuestTypeColor(_nextType);
    final icon = GameHelper.getIconForCategory(_nextType);
    final isNewUser = user.totalLevelsCompleted == 0;

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

    final String subtitle;
    if (isNewUser) {
      subtitle = context.tr(
        'home.first_step_in_category',
        fallback: 'First step in {} • Milestone: {}',
        args: [categoryLabel, milestone.target.toString()],
      );
    } else if (remaining > 1) {
      subtitle = context.tr(
        'home.levels_to_reach_milestone',
        fallback: '$remaining levels to reach Milestone ${milestone.target}',
        args: [remaining.toString(), milestone.target.toString()],
      );
    } else if (remaining == 1) {
      subtitle = context.tr(
        'home.level_to_reach_milestone',
        fallback: '1 level to reach Milestone ${milestone.target}',
        args: [milestone.target.toString()],
      );
    } else {
      subtitle = context.tr(
        'home.milestone_completed',
        fallback: 'Milestone ${milestone.target} completed! Keep mastering',
        args: [milestone.target.toString()],
      );
    }

    final String levelsTag = isNewUser
        ? context.tr('home.new_journey', fallback: 'New Journey')
        : context.tr(
            'home.levels_cleared_tag',
            fallback: '$_cleared Levels Cleared',
            args: [_cleared.toString()],
          );

    final semanticLabel = isNewUser
        ? '$title. $categoryLabel.'
        : '$title. $categoryLabel. $_cleared out of ${milestone.target} levels cleared.';

    final card = Semantics(
      button: true,
      label: semanticLabel,
      child: ScaleButton(
        onTap: () {
          try {
            di.sl<HapticService>().selection();
          } catch (_) {}
          context.push(
            '${AppRouter.categoryGamesRoute}?category=${Uri.encodeQueryComponent(_nextType.name)}',
          );
        },
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A29) : Colors.white,
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF131A29), Color(0xFF0D1320)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.32 : 0.20),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? color.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // ── Subtle Accent Border Glow on Left Edge ───────────
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3.5.r,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          bottomLeft: Radius.circular(24.r),
                        ),
                      ),
                    ),
                  ),

                  // ── Elegant Watermark Glyph ─────────────────────────
                  Positioned(
                    right: -10.r,
                    top: -10.r,
                    child: Icon(
                      icon,
                      size: 106.r,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.035)
                          : color.withValues(alpha: 0.045),
                    ),
                  ),

                  // ── Main Cockpit Content ────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Category Pill (Left) & Real Level Tag (Right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category pill
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: isDark ? 0.14 : 0.08),
                                borderRadius: BorderRadius.circular(100.r),
                                border: Border.all(
                                  color: color.withValues(alpha: isDark ? 0.28 : 0.20),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: color, size: 13.r),
                                  SizedBox(width: 5.w),
                                  Flexible(
                                    child: Text(
                                      categoryLabel,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // Real levels tag
                          Text(
                            levelsTag,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.slate400 : AppColors.slate500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate900,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // Contextual Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.slate300 : AppColors.slate600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16.h),

                      // ── Inset Cockpit Bottom Tray ────────────────────
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.035)
                              : AppColors.slate50,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
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
                                    children: [
                                      Expanded(
                                        child: Text(
                                          context.tr(
                                            'home.milestone_progress',
                                            fallback: 'Milestone Progress',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.slate400
                                                : AppColors.slate500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '$_cleared / ${milestone.target}',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w800,
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
                                          widthFactor: milestoneProgress.clamp(
                                            isNewUser ? 0.02 : 0.04,
                                            1.0,
                                          ),
                                          child: Container(
                                            height: 6.h,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(100.r),
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
                            SizedBox(width: 14.w),

                            // Tactile Primary Button
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 9.h,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isNewUser
                                        ? context.tr(
                                            'home.start',
                                            fallback: 'Start',
                                          )
                                        : context.tr(
                                            'home.resume',
                                            fallback: 'Resume',
                                          ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w800,
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

  /// Shimmer skeleton matching the exact proportions of the Apex Cockpit card.
  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark
        ? const Color(0xFF131A29)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: baseBg,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Category pill on left + level tag on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerLoading.rounded(
                  width: 90.w,
                  height: 22.h,
                  borderRadius: 100.r,
                ),
                ShimmerLoading.rounded(
                  width: 80.w,
                  height: 14.h,
                  borderRadius: 4.r,
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Title shimmer
            ShimmerLoading.rounded(
              width: 170.w,
              height: 22.h,
              borderRadius: 6.r,
            ),
            SizedBox(height: 6.h),

            // Subtitle shimmer
            ShimmerLoading.rounded(
              width: 210.w,
              height: 14.h,
              borderRadius: 4.r,
            ),
            SizedBox(height: 18.h),

            // Inset tray shimmer
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : AppColors.slate50,
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
                              width: 90.w,
                              height: 12.h,
                              borderRadius: 4.r,
                            ),
                            ShimmerLoading.rounded(
                              width: 32.w,
                              height: 12.h,
                              borderRadius: 4.r,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ShimmerLoading.rounded(
                          width: double.infinity,
                          height: 6.h,
                          borderRadius: 100.r,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 14.w),
                  ShimmerLoading.rounded(
                    width: 76.w,
                    height: 32.h,
                    borderRadius: 12.r,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
