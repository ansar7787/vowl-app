import 'dart:async';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/leaderboard/domain/utils/leaderboard_countdown_helper.dart';

/// Animated header title displaying syllabus ranking descriptions and cache freshness timestamp.
class LeaderboardHeader extends StatefulWidget {
  final DateTime lastUpdated;
  final bool isKids;
  final Future<void> Function()? onSync;

  const LeaderboardHeader({
    super.key,
    required this.lastUpdated,
    this.isKids = false,
    this.onSync,
  });

  @override
  State<LeaderboardHeader> createState() => _LeaderboardHeaderState();
}

class _LeaderboardHeaderState extends State<LeaderboardHeader>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  late final AnimationController _syncAnimController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Refresh time-ago timestamp badge every minute to keep display accurate
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _syncAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    HapticFeedback.mediumImpact();

    if (widget.onSync == null) {
      _showUpdateInfo();
      return;
    }

    setState(() => _isSyncing = true);
    _syncAnimController.repeat();

    try {
      await widget.onSync!();
      if (!mounted) return;
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'leaderboard.sync_success',
          fallback: 'Leaderboard updated with latest scores!',
        ),
        type: CustomSnackBarType.success,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      if (!mounted) return;
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'leaderboard.sync_error',
          fallback: 'Unable to refresh leaderboard. Please try again.',
        ),
        type: CustomSnackBarType.error,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        _syncAnimController.stop();
        _syncAnimController.reset();
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showUpdateInfo() {
    HapticFeedback.lightImpact();
    final countdown = LeaderboardCountdownHelper.getRemainingFormatted();
    CustomSnackBar.show(
      context: context,
      message: context.tr(
        'leaderboard.updates_info_hourly',
        fallback:
            'Rankings recalculate hourly at the top of the hour. Next update in {0}. Play quests to climb the leaderboard!',
        args: [countdown],
      ),
      type: CustomSnackBarType.info,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo = _formatTimeAgo(context, widget.lastUpdated);
    final countdown = LeaderboardCountdownHelper.getRemainingFormatted();

    final header = Semantics(
      // Announce title, subtitle, next update countdown, and last-updated time.
      label:
          '${context.tr('leaderboard.title', fallback: 'Leaderboard')}. ${context.tr('leaderboard.subtitle', fallback: 'See how you rank globally!')}. ${context.tr('leaderboard.next_update_in', fallback: 'Next in {0}', args: [countdown])}. ${context.tr('leaderboard.updated_at', fallback: 'Updated {0}', args: [timeAgo])}',
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
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
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: context.tr(
                            'leaderboard.live_sync_tooltip',
                            fallback: 'Sync leaderboard',
                          ),
                          child: GestureDetector(
                            onTap: _handleSync,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 9.w,
                                vertical: 4.h,
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
                                  RotationTransition(
                                    turns: _syncAnimController,
                                    child: Icon(
                                      Icons.update_rounded,
                                      color: isDark
                                          ? AppColors.blue300
                                          : AppColors.indigo500,
                                      size: 12.r,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _isSyncing
                                          ? context.tr(
                                              'leaderboard.syncing',
                                              fallback: 'Syncing...',
                                            )
                                          : context.tr(
                                              'leaderboard.live_sync',
                                              fallback: 'Live Sync',
                                            ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.blue300
                                            : AppColors.indigo500,
                                      ),
                                      maxLines: 1,
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
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : AppColors.slate600,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    _buildUpdateCountdownBadge(
                      context,
                      isDark,
                      countdown,
                      timeAgo,
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

  /// Renders a small, elegant countdown capsule with last-updated freshness text.
  /// Designed to remain subtle and non-intrusive while giving instant temporal context.
  Widget _buildUpdateCountdownBadge(
    BuildContext context,
    bool isDark,
    String countdown,
    String timeAgo,
  ) {
    final nextUpdateText = context.tr(
      'leaderboard.next_update_in',
      fallback: 'Next in {0}',
      args: [countdown],
    );

    return Semantics(
      label: context.tr(
        'leaderboard.next_update_accessibility',
        fallback: 'Next leaderboard update in {0}. Data was updated {1}.',
        args: [countdown, timeAgo],
      ),
      child: GestureDetector(
        onTap: _showUpdateInfo,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Micro countdown capsule (staying small and refined)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 7.w,
                vertical: 2.5.h,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.indigo500.withValues(alpha: 0.16)
                    : AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.indigo500.withValues(alpha: 0.35)
                      : AppColors.indigo500.withValues(alpha: 0.20),
                  width: 0.8.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 10.sp,
                    color: isDark ? AppColors.blue300 : AppColors.indigo600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    nextUpdateText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.blue300 : AppColors.indigo600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            // Subtle "• Updated X ago" indicator
            Flexible(
              child: Text(
                '•  $timeAgo',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : AppColors.slate400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
