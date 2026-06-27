import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/constants/app_constants.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

class LeaderboardRankCard extends StatelessWidget {
  final List<UserEntity> allUsers;
  static const int _totalLevels = AppConstants.totalCurriculumLevels;

  const LeaderboardRankCard({super.key, required this.allUsers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reactively watch for current user profile changes only.
    final currentUser = context.select<AuthBloc, UserEntity?>(
      (bloc) => bloc.state.user,
    );
    if (currentUser == null) return const SizedBox.shrink();

    final rankIndex = allUsers.indexWhere((u) => u.id == currentUser.id);
    final rank = rankIndex != -1 ? rankIndex + 1 : 0;
    final isRanked = rank > 0;

    final levelsCleared = currentUser.totalLevelsCompleted;
    final progress = (levelsCleared / _totalLevels).clamp(0.0, 1.0);
    final contrastColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? Colors.white60
        : const Color(0xFF64748B);

    return Semantics(
      // FIX (HIGH-5): Full accessibility label so TalkBack/VoiceOver
      // announces the user's rank and progress in one utterance.
      label: isRanked
          ? '${context.tr('leaderboard.your_standing')}. '
                '${context.tr('leaderboard.rank')}: $rank. '
                '$levelsCleared ${context.tr('leaderboard.levels_cleared')}. '
                '${(progress * 100).toStringAsFixed(1)}% complete.'
          : '${context.tr('leaderboard.join_competition')}. '
                '$levelsCleared ${context.tr('leaderboard.levels_cleared')}.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: GlassTile(
          padding: EdgeInsets.all(16.r),
          borderRadius: BorderRadius.circular(24.r),
          borderColor: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFCBD5E1),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.95),
          borderWidth: 1.5,
          child: Column(
            children: [
              Row(
                children: [
                  // Rank circle
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isRanked ? '#$rank' : '?',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  // Avatar
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white24
                            : Colors.black.withValues(alpha: 0.05),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: ShimmerImage(
                        imageUrl: currentUser.photoUrl ?? '',
                        width: 40.r,
                        height: 40.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Name + label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRanked
                              ? context.tr('leaderboard.your_standing')
                              : context.tr('leaderboard.join_competition'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: secondaryTextColor,
                            letterSpacing: 2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser.displayName?.toUpperCase() ??
                              context.tr('leaderboard.player'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: contrastColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Levels badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFF94A3B8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFF94A3B8).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$levelsCleared',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF334155),
                            height: 1,
                          ),
                        ),
                        Text(
                          context.tr('leaderboard.levels'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 6.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.02, 1.0),
                    child: Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        ),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      context.tr(
                        'leaderboard.all_quests',
                        args: [(progress * 100).toStringAsFixed(1)],
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$levelsCleared / $_totalLevels',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: secondaryTextColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }
}
