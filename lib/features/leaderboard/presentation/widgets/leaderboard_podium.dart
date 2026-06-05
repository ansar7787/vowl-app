import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';

class LeaderboardPodium extends StatelessWidget {
  final List<UserEntity> top3;

  const LeaderboardPodium({
    super.key,
    required this.top3,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 300.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (top3.length > 1)
            Expanded(child: _buildPodiumSlot(context, top3[1], 2))
          else
            const Expanded(child: SizedBox.shrink()),

          SizedBox(width: 8.w),

          // 1st Place
          Expanded(child: _buildPodiumSlot(context, top3[0], 1)),

          SizedBox(width: 8.w),

          // 3rd Place
          if (top3.length > 2)
            Expanded(child: _buildPodiumSlot(context, top3[2], 3))
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPodiumSlot(BuildContext context, UserEntity user, int rank) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 72.r : 56.r;
    final podiumHeight = isFirst ? 140.h : (rank == 2 ? 110.h : 90.h);
    final colors = _getRankColors(rank);
    final levelsCleared = user.totalLevelsCompleted;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown for #1
        if (isFirst)
          Text('👑', style: TextStyle(fontSize: 22.sp))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -2,
                end: 2,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),

        if (isFirst) SizedBox(height: 2.h),

        // Avatar
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
            ),
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
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
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
                  style: TextStyle(fontFamily: 'Outfit', 
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

        // Podium Column
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          (user.displayName ?? 'Player')
                              .split(' ')
                              .first
                              .toUpperCase(),
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: isFirst ? 11.sp : 9.sp,
                            fontWeight: FontWeight.w900,
                            color: MeshGradientBackground.getContrastColor(
                              context,
                            ),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
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
                // Levels Cleared
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: colors[0].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '$levelsCleared LVS',
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: isFirst ? 8.sp : 7.sp,
                        fontWeight: FontWeight.w900,
                        color: colors[0],
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${user.totalExp} XP',
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: isFirst ? 7.sp : 6.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black45,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getRankColors(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFF59E0B)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF94A3B8)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFFA3713B)];
      default:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    }
  }
}
