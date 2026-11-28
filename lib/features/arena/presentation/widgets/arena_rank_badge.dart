import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_rank.dart';

/// Compact pill displaying a player's [ArenaRank] tier.
/// Supports compact mode (for score HUD / player cards) and expanded mode (for stats screen).
class ArenaRankBadge extends StatelessWidget {
  final ArenaRank rank;
  final bool compact;
  final bool isDark;

  const ArenaRankBadge({
    super.key,
    required this.rank,
    this.compact = true,
    this.isDark = false,
  });

  factory ArenaRankBadge.fromWins({
    Key? key,
    required int duelWins,
    bool compact = true,
    bool isDark = false,
  }) {
    return ArenaRankBadge(
      key: key,
      rank: duelWins.arenaRank,
      compact: compact,
      isDark: isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = rank.color;
    final rankLabel = context.tr(
      'arena.rank_${rank.name}',
      fallback: rank.label,
    );

    if (compact) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: color.withValues(alpha: 0.40),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(rank.icon, size: 10.sp, color: color),
            SizedBox(width: 3.w),
            Text(
              rankLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: rank.gradientColors),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rank.icon, size: 13.sp, color: Colors.white),
          SizedBox(width: 5.w),
          Text(
            '${rank.emoji} ${rankLabel.toUpperCase()}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
