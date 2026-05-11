import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/constants/app_constants.dart';

/// A compact card showing the user's total quest progress across all 8 categories
/// and their current global leaderboard rank.
class GlobalProgressCard extends StatelessWidget {
  final UserEntity user;
  final int? globalRank;

  const GlobalProgressCard({super.key, required this.user, this.globalRank});

  static const int totalLevels = AppConstants.totalCurriculumLevels;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = user.totalLevelsCompleted;
    final progress = (completed / totalLevels).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(1);

    return ScaleButton(
      onTap: () => context.push(AppRouter.leaderboardRoute),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: GlassTile(
          borderRadius: BorderRadius.circular(28.r),
          padding: EdgeInsets.all(20.r),
          borderColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.route_rounded,
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
                          'QUEST JOURNEY',
                          style: GoogleFonts.outfit(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6366F1),
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Total Levels Cleared',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Global Rank Badge
                  if (globalRank != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getRankGradient(globalRank!),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: _getRankGradient(
                              globalRank!,
                            ).first.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '#$globalRank',
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Text(
                            'RANK',
                            style: GoogleFonts.outfit(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              SizedBox(height: 18.h),

              // Progress Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$completed',
                          style: GoogleFonts.outfit(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6366F1),
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: ' / $totalLevels Levels',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$percentage% Complete',
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                      // Category mini badges
                      Row(
                        children: [
                          _buildCategoryDot(
                            context,
                            '📖',
                            user.getTotalCategoryLevelsCleared(QuestType.reading),
                          ),
                          _buildCategoryDot(
                            context,
                            '✍️',
                            user.getTotalCategoryLevelsCleared(QuestType.writing),
                          ),
                          _buildCategoryDot(
                            context,
                            '🎤',
                            user.getTotalCategoryLevelsCleared(QuestType.speaking),
                          ),
                          _buildCategoryDot(
                            context,
                            '🎧',
                            user.getTotalCategoryLevelsCleared(QuestType.listening),
                          ),
                          _buildCategoryDot(
                            context,
                            '🏆',
                            user.getTotalCategoryLevelsCleared(QuestType.eliteMastery),
                          ),
                        ],
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
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFFA855F7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(
                        duration: 2500.ms,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCategoryDot(BuildContext context, String emoji, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(left: 3.w),
      child: Tooltip(
        message: '$count levels',
        child: Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(emoji, style: TextStyle(fontSize: 10.sp)),
        ),
      ),
    );
  }

  List<Color> _getRankGradient(int rank) {
    if (rank == 1) return [const Color(0xFFFFD700), const Color(0xFFF59E0B)];
    if (rank == 2) return [const Color(0xFFC0C0C0), const Color(0xFF94A3B8)];
    if (rank == 3) return [const Color(0xFFCD7F32), const Color(0xFFA3713B)];
    if (rank <= 10) return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
  }
}
