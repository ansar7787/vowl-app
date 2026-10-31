import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/leaderboard/domain/utils/leaderboard_countdown_helper.dart';

/// Animated header title displaying syllabus ranking descriptions and cache freshness timestamp.
class LeaderboardHeader extends StatefulWidget {
  final DateTime lastUpdated;
  final bool isKids;

  const LeaderboardHeader({
    super.key,
    required this.lastUpdated,
    this.isKids = false,
  });

  @override
  State<LeaderboardHeader> createState() => _LeaderboardHeaderState();
}

class _LeaderboardHeaderState extends State<LeaderboardHeader> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Refresh countdown badge every 30 seconds to keep remaining time accurate
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showUpdateInfo(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                context.tr(
                  'leaderboard.updates_info',
                  fallback:
                      'Rankings refresh automatically every 4 hours. Play quests to climb the leaderboard in the next update!',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.slate800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeUntilNext = LeaderboardCountdownHelper.getRemainingFormatted();
    final timeAgo = _formatTimeAgo(context, widget.lastUpdated);

    final header = Semantics(
      // FIX (HIGH-5): Screen readers now announce the leaderboard title,
      // subtitle, and when it was last updated in a single label.
      label:
          '${context.tr('leaderboard.title', fallback: 'Leaderboard')}. ${context.tr('leaderboard.subtitle', fallback: 'See how you rank globally!')}. ${context.tr('leaderboard.updated_at', fallback: 'Updated {0}', args: [timeAgo])}',
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
                    colors: [
                      IllustrationColors.premiumGold,
                      AppColors.amber500,
                    ],
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
                            widget.isKids
                                ? context.tr(
                                    'leaderboard.kids_title',
                                    fallback: 'Kids Leaderboard',
                                  )
                                : context.tr(
                                    'leaderboard.title',
                                    fallback: 'Leaderboard',
                                  ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ExcludeSemantics(
                          child: GestureDetector(
                            onTap: () => _showUpdateInfo(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.indigo500.withValues(
                                        alpha: 0.20,
                                      )
                                    : AppColors.indigo500.withValues(
                                        alpha: 0.08,
                                      ),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.indigo500.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppColors.indigo500.withValues(
                                          alpha: 0.2,
                                        ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.update_rounded,
                                    color: isDark
                                        ? AppColors.blue300
                                        : AppColors.indigo500,
                                    size: 12.r,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    context.tr(
                                      'leaderboard.next_update_in',
                                      fallback: 'Next in {0}',
                                      args: [timeUntilNext],
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.blue300
                                          : AppColors.indigo500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      widget.isKids
                          ? context.tr(
                              'leaderboard.kids_subtitle',
                              fallback: 'See how your child ranks globally!',
                            )
                          : context.tr(
                              'leaderboard.subtitle',
                              fallback: 'See how you rank globally!',
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (VowlMotion.shouldReduceMotion(context)) return header;
    return header.animate().fadeIn(duration: 500.ms);
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return context.tr('leaderboard.just_now', fallback: 'Just now');
    }
    if (difference.inMinutes < 60) {
      return context.tr(
        'leaderboard.mins_ago',
        fallback: '{0} mins ago',
        args: [difference.inMinutes.toString()],
      );
    }
    if (difference.inHours < 24) {
      return context.tr(
        'leaderboard.hours_ago',
        fallback: '{0} hours ago',
        args: [difference.inHours.toString()],
      );
    }
    return context.tr(
      'leaderboard.days_ago',
      fallback: '{0} days ago',
      args: [difference.inDays.toString()],
    );
  }
}
