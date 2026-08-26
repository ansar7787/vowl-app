import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// A compact card showing the user's total quest progress across all 8 categories
/// and their current global leaderboard rank.
class KidsGlobalProgressCard extends StatelessWidget {
  final UserEntity user;
  final int? globalRank;

  const KidsGlobalProgressCard({
    super.key,
    required this.user,
    this.globalRank,
  });

  static const int totalLevels = 5000;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = user.kidsTotalLevelsCompleted;
    final progress = totalLevels > 0
        ? (completed / totalLevels).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toStringAsFixed(1);
    final rankGradient = globalRank != null
        ? _getRankGradient(globalRank!)
        : null;

    return Semantics(
      button: true,
      label: context.tr(
        'kids_zone.learning_progress_progress_label',
        fallback: 'Journey Progress',
        args: [completed.toString(), totalLevels.toString(), percentage],
      ),
      child: ScaleButton(
        onTap: () => context.push(AppRouter.kidsLeaderboardRoute),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: GlassTile(
            borderRadius: BorderRadius.circular(28.r),
            padding: EdgeInsets.all(20.r),
            borderColor: const Color(0xFFF43F5E).withValues(alpha: 0.3),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Quest Icon
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF43F5E,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.child_care_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'kids_zone.learning_progress',
                                fallback: 'Kids Learning Progress',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF43F5E),
                                letterSpacing: 2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              context.tr(
                                'home.total_levels_cleared',
                                fallback: 'Total Levels Cleared',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Global Rank Badge
                      if (globalRank != null && rankGradient != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: rankGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: rankGradient.first.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '#$globalRank',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                                maxLines: 1,
                              ),
                              Text(
                                context.tr('home.rank', fallback: 'Rank'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 1.5,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: 48.w,
                          height: 38.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(
                              duration: 1500.ms,
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                            ),
                    ],
                  ),

                  SizedBox(height: 18.h),

                  // Progress Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$completed',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFF43F5E),
                              height: 1,
                            ),
                          ),
                          Text(
                            context.tr(
                              'home.levels_suffix',
                              fallback: 'Levels',
                              args: [totalLevels.toString()],
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr(
                              'home.percent_complete',
                              fallback: 'Complete',
                              args: [percentage.toString()],
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Progress Bar
                  RepaintBoundary(
                    child: Stack(
                      children: [
                        Container(
                          height: 8.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.02, 1.0),
                          child: Container(
                            height: 8.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF43F5E),
                                  Color(0xFFE11D48),
                                  Color(0xFFBE123C),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
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
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  List<Color> _getRankGradient(int rank) {
    if (rank == 1) return [const Color(0xFFFFD700), const Color(0xFFF59E0B)];
    if (rank == 2) return [const Color(0xFFC0C0C0), const Color(0xFF94A3B8)];
    if (rank == 3) return [const Color(0xFFCD7F32), const Color(0xFFA3713B)];
    if (rank <= 10) return [const Color(0xFF3B82F6), const Color(0xFFF43F5E)];
    return [const Color(0xFFF43F5E), const Color(0xFFE11D48)];
  }
}
