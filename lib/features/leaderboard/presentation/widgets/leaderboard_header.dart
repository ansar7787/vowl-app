import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class LeaderboardHeader extends StatelessWidget {
  final DateTime lastUpdated;

  const LeaderboardHeader({super.key, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo = _formatTimeAgo(context, lastUpdated);

    return Semantics(
      // FIX (HIGH-5): Screen readers now announce the leaderboard title,
      // subtitle, and when it was last updated in a single label.
      label:
          '${context.tr('leaderboard.title', fallback: 'Leaderboard')}. ${context.tr('leaderboard.subtitle', fallback: 'See how you rank')}. ${context.tr('leaderboard.updated_at', args: [timeAgo])}',
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.leaderboard_rounded,
                  color: Colors.white,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            context.tr('leaderboard.title', fallback: 'Leaderboard'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ExcludeSemantics(
                          // The parent Semantics already announces timeAgo.
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 10.r,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      context.tr('leaderboard.subtitle', fallback: 'See how you rank'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return context.tr('leaderboard.just_now', fallback: 'Just now');
    }
    if (difference.inMinutes < 60) {
      return context.tr(
        'leaderboard.mins_ago',
        args: [difference.inMinutes.toString()],
      );
    }
    if (difference.inHours < 24) {
      return context.tr(
        'leaderboard.hours_ago',
        args: [difference.inHours.toString()],
      );
    }
    return context.tr(
      'leaderboard.days_ago',
      args: [difference.inDays.toString()],
    );
  }
}
