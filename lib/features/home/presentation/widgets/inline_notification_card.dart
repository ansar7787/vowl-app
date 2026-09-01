import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class InlineNotificationCard extends StatefulWidget {
  final int streak;

  const InlineNotificationCard({super.key, required this.streak});

  @override
  State<InlineNotificationCard> createState() => _InlineNotificationCardState();
}

class _InlineNotificationCardState extends State<InlineNotificationCard>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _isVisible = ValueNotifier(false);
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isGranted = await Permission.notification.isGranted;
      final bool isDeniedForever =
          await Permission.notification.isPermanentlyDenied;

      if (!mounted) return;

      // If user explicitly disabled notifications from Settings Screen, we respect that too.
      final bool appSettingsEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      if (isGranted || isDeniedForever || !appSettingsEnabled) {
        _isVisible.value = false;
        return;
      }

      // Cooldown logic: don't show every single time if they dismissed it.
      final int? lastDismissedMs = prefs.getInt(
        'notification_card_dismissed_time',
      );
      if (lastDismissedMs != null) {
        final lastDismissedDate = DateTime.fromMillisecondsSinceEpoch(
          lastDismissedMs,
        );
        final daysDifference = DateTime.now()
            .difference(lastDismissedDate)
            .inDays;
        if (daysDifference < 7) {
          _isVisible.value = false;
          return;
        }
      }

      _isVisible.value = true;
      _animationController.forward();
    } catch (e) {
      // Permission/preferences lookup failures should never crash the home
      // feed — simply keep the card hidden and trace it in debug builds.
      if (kDebugMode) {
        debugPrint('InlineNotificationCard: permission check failed: $e');
      }
      if (mounted) _isVisible.value = false;
    }
  }

  Future<void> _requestPermission() async {
    di.sl<HapticService>().selection();
    final status = await Permission.notification.request();
    if (!mounted) return;

    if (status.isGranted) {
      di.sl<HapticService>().success();
      await _animationController.reverse();
      if (mounted) _isVisible.value = false;
    } else {
      _dismissCard();
    }
  }

  Future<void> _dismissCard() async {
    di.sl<HapticService>().light();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'notification_card_dismissed_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InlineNotificationCard: failed to persist dismissal: $e');
      }
    }

    if (mounted) {
      await _animationController.reverse();
      if (mounted) _isVisible.value = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getDynamicTitle() {
    final hour = DateTime.now().hour;
    final streak = widget.streak;

    if (streak >= 3) {
      final streakTitles = [
        context
            .tr('notification_card.streak_protect')
            .replaceAll('{}', streak.toString()),
        context
            .tr('notification_card.streak_strong')
            .replaceAll('{}', streak.toString()),
        context.tr(
          'notification_card.streak_unstoppable',
          fallback: 'Unstoppable!',
        ),
        context
            .tr('notification_card.streak_dont_lose')
            .replaceAll('{}', streak.toString()),
      ];
      return streakTitles[hour % streakTitles.length];
    } else if (streak == 1 || streak == 2) {
      final starterTitles = [
        context.tr('notification_card.starter_on_roll', fallback: 'On a Roll!'),
        context.tr(
          'notification_card.starter_momentum',
          fallback: 'Keep the Momentum!',
        ),
        context.tr(
          'notification_card.starter_begun',
          fallback: 'Journey Begun!',
        ),
      ];
      return starterTitles[hour % starterTitles.length];
    }

    // Streak is 0
    if (hour < 12) {
      return context.tr(
        'notification_card.morning_quest',
        fallback: 'Morning Quest',
      );
    } else if (hour < 17) {
      return context.tr(
        'notification_card.afternoon_practice',
        fallback: 'Afternoon Practice',
      );
    } else if (hour < 21) {
      return context.tr(
        'notification_card.evening_boost',
        fallback: 'Evening Boost',
      );
    } else {
      return context.tr('notification_card.night_owl', fallback: 'Night Owl');
    }
  }

  String _getDynamicSubtitle() {
    if (widget.streak >= 3) {
      return context.tr(
        'notification_card.subtitle_streak',
        fallback: 'Your streak is growing.',
      );
    }
    return context.tr(
      'notification_card.subtitle_default',
      fallback: 'Time for your next quest.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isVisible,
      builder: (context, isVisible, _) {
        if (!isVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _getDynamicTitle();
    final subtitle = _getDynamicSubtitle();

    return SizeTransition(
      sizeFactor: _animationController,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: 8.h,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.08),
                  blurRadius: 24.r,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 48.r,
                          height: 48.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                color: const Color(0xFFF97316),
                                size: 24.r,
                              ),
                              PositionedDirectional(
                                top: 10.r,
                                end: 12.r,
                                child: Container(
                                  width: 10.r,
                                  height: 10.r,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      width: 1.5.r,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.only(end: 24.w),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44.h,
                                    child: ElevatedButton(
                                      onPressed: _requestPermission,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF97316),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        context.tr(
                                          'notification_card.remind_me',
                                          fallback: 'Remind Me',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: SizedBox(
                                    height: 44.h,
                                    child: TextButton(
                                      onPressed: _dismissCard,
                                      style: TextButton.styleFrom(
                                        foregroundColor: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        backgroundColor: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        context.tr(
                                          'notification_card.not_now',
                                          fallback: 'Not Now',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Semantics(
                    button: true,
                    label: context.tr('common.close', fallback: 'Close'),
                    child: GestureDetector(
                      onTap: _dismissCard,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        // Fixed 48x48 invisible hit area anchored at the
                        // card's corner; centering the original 24x24 glyph
                        // inside it reproduces the exact same visual offset
                        // (12,12) the design had, while satisfying the 48dp
                        // minimum accessible touch target.
                        width: 48.r,
                        height: 48.r,
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16.r,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      }
    );
  }
}
