import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class LeaderboardPodium extends StatelessWidget {
  final List<UserEntity> top3;
  final bool isKids;

  const LeaderboardPodium({super.key, required this.top3, this.isKids = false});

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    // FIX (MEDIUM-2): Replace fixed SizedBox(height: 300.h) with a
    // LayoutBuilder-constrained height. On short devices (e.g. 568px tall),
    // 300.h would consume ~54% of visible height before the app bar.
    // Capping at 40% of screen height keeps the podium proportional.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPodiumHeight = (MediaQuery.of(context).size.height * 0.40)
            .clamp(220.0, 320.0);

        return SizedBox(
              height: maxPodiumHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd Place (left)
                  if (top3.length > 1)
                    Expanded(
                      child: _PodiumSlot(
                        user: top3[1],
                        rank: 2,
                        maxHeight: maxPodiumHeight,
                        isKids: isKids,
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
                      isKids: isKids,
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
                        isKids: isKids,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, curve: Curves.easeOutCirc)
            .slideY(
              begin: 0.2,
              end: 0,
              curve: Curves.easeOutBack,
              duration: 800.ms,
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
  final bool isKids;

  const _PodiumSlot({
    required this.user,
    required this.rank,
    required this.maxHeight,
    this.isKids = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 72.r : 56.r;
    // Scale podium column heights proportionally against the max height.
    final podiumHeight = isFirst
        ? maxHeight * 0.46
        : (rank == 2 ? maxHeight * 0.36 : maxHeight * 0.30);
    final colors = _rankColors(rank);
    final levelsCleared = isKids
        ? user.kidsTotalLevelsCompleted
        : user.totalLevelsCompleted;
    final score = isKids ? user.kidsCoins : user.totalExp;
    final scoreLabel = isKids ? 'Coins' : 'XP';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      // FIX (HIGH-5): Screen readers now announce the rank, player name,
      // levels cleared, and XP for each podium position.
      // FIX (HIGH-2): "Player" fallback localised via context.tr().
      label:
          'Rank $rank: ${user.displayName ?? context.tr("leaderboard.player", fallback: 'Player')}. '
          '$levelsCleared levels cleared. $score $scoreLabel.',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown for 1st place — extracted to avoid unnecessary rebuilds
          if (isFirst) ...[const _AnimatedCrown(), SizedBox(height: 2.h)],

          // Avatar with glow ring + rank badge
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                    width: avatarSize + 12,
                    height: avatarSize + 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors[0].withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1.0,
                    end: isFirst ? 1.08 : 1.0,
                    duration: 1500.ms,
                  )
                  .fade(begin: 0.8, end: 1.0),
              // Photo
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors[0].withValues(alpha: 0.7),
                    width: isFirst ? 3 : 2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.r),
                  child: ClipOval(
                    child: ShimmerImage(
                      imageUrl: user.photoUrl ?? '',
                      width: avatarSize - 8,
                      height: avatarSize - 8,
                    ),
                  ),
                ),
              ),
              // Rank badge
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
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
            ],
          ),

          SizedBox(height: 6.h),

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
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
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
                          (user.displayName ?? 'Player')
                              .split(' ')
                              .first
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isFirst ? 11.sp : 9.sp,
                            fontWeight: FontWeight.w900,
                            color: MeshGradientBackground.getContrastColor(
                              context,
                            ),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          minFontSize: 6,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (user.isPremium)
                        Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(
                            Icons.verified_rounded,
                            color: const Color(0xFFF59E0B),
                            size: isFirst ? 12.r : 10.r,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Levels cleared badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: colors[0].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: AutoSizeText(
                      context.tr(
                        'leaderboard.lvs',
                        fallback: 'Lvs',
                        args: [levelsCleared.toString()],
                      ),
                      maxLines: 1,
                      minFontSize: 4,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: isFirst ? 8.sp : 7.sp,
                        fontWeight: FontWeight.w900,
                        color: colors[0],
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  AutoSizeText(
                    '$score $scoreLabel',
                    maxLines: 1,
                    minFontSize: 4,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isFirst ? 7.sp : 6.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<Color> _rankColors(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFF59E0B)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF94A3B8)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFFA3713B)];
      default:
        return [const Color(0xFF3B82F6), const Color(0xFF6366F1)];
    }
  }
}

// ---------------------------------------------------------------------------
// Private: animated crown — extracted so parent rebuilds don't restart the
// floating animation from frame 0.
// ---------------------------------------------------------------------------

class _AnimatedCrown extends StatelessWidget {
  const _AnimatedCrown();

  @override
  Widget build(BuildContext context) {
    return Text('👑', style: TextStyle(fontSize: 22.sp))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -2, end: 2, duration: 1500.ms, curve: Curves.easeInOut);
  }
}
