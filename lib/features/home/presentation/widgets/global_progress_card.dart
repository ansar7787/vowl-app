import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/constants/app_constants.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// A precision telemetry card displaying macro curriculum mastery and global leaderboard rank.
///
/// Refactored to Concept 4 (The Apex Macro-Mastery Cockpit):
/// - Tactical route lockup with accessible typography.
/// - Prestige Leaderboard rank pill with clear navigation affordance.
/// - Authentic mathematical stage telemetry (100% real data, zero fake numbers).
/// - Pure solid brand indigo track (zero forbidden multi-color gradients).
/// - Responsive and resilient down to compact 320dp viewports.
class GlobalProgressCard extends StatelessWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Current global ranking position, or `null` if unranked.
  final int? globalRank;

  /// Creates a [GlobalProgressCard] for [user] with optional [globalRank].
  const GlobalProgressCard({super.key, required this.user, this.globalRank});

  /// Total available curriculum levels across all main game types.
  static const int totalLevels = AppConstants.totalCurriculumLevels;

  void _triggerHaptic() {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
  }

  static int _getCurriculumStageNumber(int completed) {
    if (completed < 50) return 1;
    if (completed < 200) return 2;
    if (completed < 1000) return 3;
    return 4;
  }

  static String _getCurriculumStageName(BuildContext context, int completed) {
    if (completed < 50) {
      return context.tr('home.stage_foundation', fallback: 'Foundation');
    }
    if (completed < 200) {
      return context.tr('home.stage_intermediate', fallback: 'Intermediate');
    }
    if (completed < 1000) {
      return context.tr('home.stage_advanced', fallback: 'Advanced');
    }
    return context.tr('home.stage_mastery', fallback: 'Mastery');
  }

  static String _getMilestoneRemainingText(BuildContext context, int completed) {
    final nextTarget = completed < 50
        ? 50
        : (completed < 200
            ? 200
            : (completed < 1000 ? 1000 : totalLevels));
    final remaining = (nextTarget - completed).clamp(0, totalLevels);
    if (remaining == 0) {
      return context.tr(
        'home.curriculum_completed',
        fallback: 'Curriculum Mastered!',
      );
    }
    return context.tr(
      'home.remaining_to_stage_target',
      fallback: '$remaining to Next Target',
      args: [remaining.toString()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = user.totalLevelsCompleted;
    final progress = totalLevels > 0
        ? (completed / totalLevels).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toStringAsFixed(1);

    final title = context.tr(
      'home.curriculum_mastery_title',
      fallback: 'Curriculum Mastery',
    );
    final subtitle = context.tr(
      'home.curriculum_mastery_subtitle',
      fallback: 'Global Journey & Rank',
    );
    final rankText = globalRank != null ? '#$globalRank' : '—';
    final rankLabel = globalRank != null
        ? context.tr('home.rank_label', fallback: 'Rank')
        : context.tr('home.unranked', fallback: 'Unranked');

    Widget card = Semantics(
      button: true,
      label: context.tr(
        'home.quest_journey_progress_label',
        fallback: '$title. $completed of $totalLevels levels completed. $rankLabel $rankText.',
        args: [completed.toString(), totalLevels.toString(), percentage],
      ),
      child: ScaleButton(
        onTap: () {
          _triggerHaptic();
          context.push(AppRouter.leaderboardRoute);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A29) : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: AppColors.indigo500.withValues(
                alpha: isDark ? 0.30 : 0.22,
              ),
              width: 1.2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo500.withValues(
                  alpha: isDark ? 0.10 : 0.05,
                ),
                blurRadius: 16.r,
                offset: Offset(0, 4.r),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Tactical Route Lockup + Prestige Rank Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(
                        alpha: isDark ? 0.14 : 0.09,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(
                          alpha: isDark ? 0.30 : 0.20,
                        ),
                        width: 1.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.alt_route_rounded,
                        color: AppColors.indigo500,
                        size: 20.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate900,
                            letterSpacing: -0.2,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Prestige Leaderboard Rank Action Pill
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(
                          alpha: isDark ? 0.28 : 0.18,
                        ),
                        width: 1.r,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rankText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.indigo500,
                            height: 1,
                          ),
                          maxLines: 1,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          rankLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate500,
                            height: 1,
                          ),
                          maxLines: 1,
                        ),
                        SizedBox(width: 2.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14.r,
                          color: AppColors.indigo500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14.h),

              // Metric Row: Large Count + Percentage Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$completed',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.indigo500,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            context.tr(
                              'home.levels_suffix',
                              fallback: '/ $totalLevels Levels',
                              args: [totalLevels.toString()],
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate500,
                              height: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(
                        alpha: isDark ? 0.14 : 0.09,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      context.tr(
                        'home.percent_complete',
                        fallback: '$percentage% Cleared',
                        args: [percentage],
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.indigo500,
                        height: 1.1,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // Solid Precision Progress Track (Zero Gradients)
              RepaintBoundary(
                child: Stack(
                  children: [
                    Container(
                      height: 7.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.015, 1.0),
                      child: Container(
                        height: 7.h,
                        decoration: BoxDecoration(
                          color: AppColors.indigo500,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // Milestone Sub-Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13.r,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Stage ${_getCurriculumStageNumber(completed)}: ${_getCurriculumStageName(context, completed)}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo500,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      _getMilestoneRemainingText(context, completed),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!VowlMotion.shouldReduceMotion(context)) {
      card = card.animate().fadeIn(duration: 400.ms).slideY(begin: 0.06);
    }

    return card;
  }
}
