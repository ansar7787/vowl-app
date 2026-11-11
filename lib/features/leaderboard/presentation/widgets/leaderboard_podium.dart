import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class _LocalPalette {
  _LocalPalette._();
  static const Color colorc0c0c0 = Color(0xFFC0C0C0);
  static const Color colorcd7f32 = Color(0xFFCD7F32);
  static const Color colora3713b = Color(0xFFA3713B);
}

/// Gamified podium widget highlighting the top 3 global ranking players with avatars and trophies.
class LeaderboardPodium extends StatelessWidget {
  final List<UserEntity> top3;
  final bool isWeekly;
  final String? currentUserId;
  final void Function(UserEntity user, int rank, bool isMe)? onUserTap;

  const LeaderboardPodium({
    super.key,
    required this.top3,
    this.isWeekly = true,
    this.currentUserId,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    // FIX (MEDIUM-2): Replace fixed SizedBox(height: 300.h) with a
    // LayoutBuilder-constrained height. On short devices (e.g. 568px tall),
    // 300.h would consume ~54% of visible height before the app bar.
    // Capping at 40% of screen height keeps the podium proportional.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPodiumHeight = (MediaQuery.sizeOf(context).height * 0.24)
            .clamp(185.0, 210.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd Place (left)
            if (top3.length > 1)
              Expanded(
                child: _PodiumSlot(
                  user: top3[1],
                  rank: 2,
                  maxHeight: maxPodiumHeight,
                  isWeekly: isWeekly,
                  currentUserId: currentUserId,
                  onUserTap: onUserTap,
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),

            SizedBox(width: 8.w),

            // 1st Place (centre)
            Expanded(
              child: _PodiumSlot(
                user: top3[0],
                rank: 1,
                maxHeight: maxPodiumHeight,
                isWeekly: isWeekly,
                currentUserId: currentUserId,
                onUserTap: onUserTap,
              ),
            ),

            SizedBox(width: 8.w),

            // 3rd Place (right)
            if (top3.length > 2)
              Expanded(
                child: _PodiumSlot(
                  user: top3[2],
                  rank: 3,
                  maxHeight: maxPodiumHeight,
                  isWeekly: isWeekly,
                  currentUserId: currentUserId,
                  onUserTap: onUserTap,
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private: individual podium slot
// ---------------------------------------------------------------------------

class _PodiumSlot extends StatelessWidget {
  final UserEntity user;
  final int rank;
  final double maxHeight;
  final bool isWeekly;
  final String? currentUserId;
  final void Function(UserEntity user, int rank, bool isMe)? onUserTap;

  const _PodiumSlot({
    required this.user,
    required this.rank,
    required this.maxHeight,
    this.isWeekly = true,
    this.currentUserId,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 62.r : 50.r;
    // Scale podium column heights proportionally against the max height.
    final podiumHeight = isFirst
        ? maxHeight * 0.50
        : (rank == 2 ? maxHeight * 0.40 : maxHeight * 0.34);
    final colors = _rankColors(rank);
    final levelsCleared = user.totalLevelsCompleted;
    final score = isWeekly ? user.currentWeeklyExp : user.totalExp;
    final scoreLabel = isWeekly
        ? context.tr('leaderboard.weekly_xp', fallback: 'Weekly XP')
        : context.tr('leaderboard.xp', fallback: 'XP');
    final isMe = currentUserId != null && user.id == currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delay = rank == 3 ? 0 : (rank == 2 ? 150 : 300);
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final safeDisplayName = user.getSafeDisplayName(
      fallback: context.tr('leaderboard.player', fallback: 'Player'),
    );

    final slotContent = Semantics(
      // FIX (HIGH-5): Screen readers now announce the rank, player name,
      // levels cleared, and XP for each podium position.
      // FIX (HIGH-2): "Player" fallback localised via context.tr().
      label:
          'Rank $rank: $safeDisplayName. '
          '$levelsCleared levels cleared. $score $scoreLabel.',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar with single bold champion ring + rank badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Single bold athletic champion border directly around avatar
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isMe ? 0.6 : 0.3),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.all(isFirst ? 3.r : 2.5.r),
                child: UserAvatar(
                  photoUrl: user.photoUrl,
                  size: avatarSize - (isFirst ? 6.r : 5.r),
                ),
              ),

              // Rank badge (#1, #2, #3)
              Positioned(
                bottom: -5.h,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9.w,
                    vertical: 2.5.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // "YOU" badge — only visible when current user is on podium
              if (isMe)
                Positioned(
                  top: -2.h,
                  right: -4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      context.tr('leaderboard.you', fallback: 'You'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 8.h),

          // Podium column
          Container(
            width: double.infinity,
            height: podiumHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[0].withValues(alpha: 0.25),
                  colors[1].withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              border: Border.all(
                color: colors[0].withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AutoSizeText(
                            safeDisplayName.split(' ').first,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: isFirst ? 12.sp : 10.5.sp,
                              fontWeight: FontWeight.w900,
                              color: MeshGradientBackground.getContrastColor(
                                context,
                              ),
                              height: 1.1,
                            ),
                            maxLines: 1,
                            minFontSize: 7,
                            softWrap: false,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (user.isPremium)
                          Padding(
                            padding: EdgeInsets.only(left: 4.w),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.amber500,
                              size: isFirst ? 12.r : 10.r,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AutoSizeText(
                            '$score $scoreLabel',
                            maxLines: 1,
                            minFontSize: 7,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: isFirst ? 10.5.sp : 9.sp,
                              fontWeight: FontWeight.w900,
                              color: rank == 2
                                  ? (isDark
                                        ? _LocalPalette.colorc0c0c0
                                        : AppColors.slate700)
                                  : colors[0].withValues(alpha: 0.9),
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isWeekly) ...[
                      SizedBox(height: 2.h),
                      _buildRankChangeIndicator(
                        user.previousRank ?? rank,
                        rank,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final interactiveSlot = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().selection();
        }
        onUserTap?.call(user, rank, isMe);
      },
      child: slotContent,
    );

    if (reduceMotion) {
      return interactiveSlot;
    }

    return interactiveSlot
        .animate(delay: delay.ms)
        .fadeIn(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.25,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 500),
        )
        .scaleXY(
          begin: 0.9,
          end: 1.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 500),
        );
  }

  Widget _buildRankChangeIndicator(int previousRank, int currentRank) {
    final diff = previousRank - currentRank;
    if (diff > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_drop_up_rounded,
            color: AppColors.emerald500,
            size: 11.r,
          ),
          Text(
            '$diff',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 7.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.emerald500,
              height: 1.0,
            ),
          ),
        ],
      );
    } else if (diff < 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.red500,
            size: 11.r,
          ),
          Text(
            '${diff.abs()}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 7.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.red500,
              height: 1.0,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4.w,
            height: 1.5.h,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ],
      );
    }
  }

  static List<Color> _rankColors(int rank) {
    switch (rank) {
      case 1:
        return [AppColors.gold, AppColors.amber500];
      case 2:
        return [_LocalPalette.colorc0c0c0, AppColors.slate400];
      case 3:
        return [_LocalPalette.colorcd7f32, _LocalPalette.colora3713b];
      default:
        return [AppColors.blue500, AppColors.indigo500];
    }
  }
}
