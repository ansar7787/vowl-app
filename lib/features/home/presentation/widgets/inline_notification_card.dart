import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Contextual prompt card nudging users to grant notification permissions to protect streaks.
class InlineNotificationCard extends StatefulWidget {
  /// Current consecutive day streak count.
  final int streak;

  /// Creates an [InlineNotificationCard] for [streak].
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
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
    final streak = widget.streak;

    if (streak >= 3) {
      return context.tr(
        'notification_card.streak_protect',
        args: [streak.toString()],
        fallback: 'Save your {}-day streak',
      );
    } else if (streak == 1 || streak == 2) {
      return context.tr(
        'notification_card.starter_momentum',
        fallback: 'Keep your momentum going!',
      );
    }

    // Streak is 0
    return context.tr(
      'notification_card.morning_quest',
      fallback: 'Never miss your daily quest!',
    );
  }

  String _getDynamicSubtitle() {
    if (widget.streak >= 3) {
      return context.tr(
        'notification_card.subtitle_streak_short',
        fallback: 'Daily alert before midnight',
      );
    }
    return context.tr(
      'notification_card.subtitle_default_short',
      fallback: 'Daily reminders at your best time',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<bool>(
      valueListenable: _isVisible,
      builder: (context, isVisible, _) {
        if (!isVisible) return const SizedBox.shrink();

        final title = _getDynamicTitle();
        final subtitle = _getDynamicSubtitle();

        return SizeTransition(
          sizeFactor: _animationController,
          axisAlignment: 0.0,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.slate900.withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: IllustrationColors.warmOrange.withValues(
                      alpha: isDark ? 0.30 : 0.22,
                    ),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: IllustrationColors.warmOrange.withValues(
                        alpha: isDark ? 0.12 : 0.06,
                      ),
                      blurRadius: 16.r,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Notification Icon with glowing tint
                    Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: IllustrationColors.warmOrange.withValues(
                          alpha: isDark ? 0.20 : 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: IllustrationColors.warmOrange,
                          size: 16.r,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Texts column (Mix 1: Crisp Punch, short & readable)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : AppColors.slate600,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Remind Me Action Pill
                    ScaleButton(
                      onTap: _requestPermission,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: IllustrationColors.warmOrange,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: IllustrationColors.warmOrange.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          context.tr(
                            'notification_card.remind_me',
                            fallback: 'Remind Me',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),

                    // Accessible Dismiss (✕)
                    Semantics(
                      button: true,
                      label: context.tr('common.close', fallback: 'Close'),
                      child: GestureDetector(
                        onTap: _dismissCard,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 28.r,
                          height: 28.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14.r,
                            color: isDark ? Colors.white60 : AppColors.slate500,
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
      },
    );
  }
}
