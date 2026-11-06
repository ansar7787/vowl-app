import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Contextual prompt card nudging users to grant notification permissions to protect streaks.
class InlineNotificationCard extends StatefulWidget {
  /// Current consecutive day streak count.
  final int streak;

  /// Creates an [InlineNotificationCard] for [streak].
  const InlineNotificationCard({super.key, required this.streak});

  /// In-memory cache of whether the card should be displayed.
  /// Allows Frame-1 instantaneous rendering without waiting for OS bridge calls.
  static bool? cachedShouldShow;

  /// Synchronously pre-evaluates fast SharedPreferences constraints (cooldown, settings)
  /// and kicks off OS permission verification in the background.
  static void prewarm(SharedPreferences prefs) {
    // 1. Respect user setting if explicitly disabled in app settings
    final bool appSettingsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    if (!appSettingsEnabled) {
      cachedShouldShow = false;
      return;
    }

    // 2. If user already granted permission, never prompt again
    final bool isGranted =
        prefs.getBool('notification_permission_granted') ?? false;
    if (isGranted) {
      cachedShouldShow = false;
      return;
    }

    // 3. 7-Day Cooldown Check:
    // If user dismissed the card or previously denied permission,
    // wait 7 full days before re-prompting.
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
        cachedShouldShow = false;
        return;
      }
    }

    // Cooldown has expired (or first run): card renders immediately on Frame 1!
    cachedShouldShow = true;

    // Asynchronously verify actual OS permission status in background
    Permission.notification.status.then((status) {
      if (status.isGranted) {
        cachedShouldShow = false;
        prefs.setBool('notification_permission_granted', true);
      }
    }).catchError((_) {});
  }

  @override
  State<InlineNotificationCard> createState() => _InlineNotificationCardState();
}

class _InlineNotificationCardState extends State<InlineNotificationCard>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<bool> _isVisible;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final initialVisible = InlineNotificationCard.cachedShouldShow ?? false;
    _isVisible = ValueNotifier(initialVisible);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: initialVisible ? 1.0 : 0.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final results = await Future.wait([
        SharedPreferences.getInstance(),
        Permission.notification.status,
      ]);
      final prefs = results[0] as SharedPreferences;
      final status = results[1] as PermissionStatus;

      if (!mounted) return;

      final bool isGranted = status.isGranted;

      // Update cached granted flag if permission is active in OS
      if (isGranted) {
        await prefs.setBool('notification_permission_granted', true);
      }

      // If user explicitly disabled notifications from Settings Screen, respect that
      final bool appSettingsEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      // 7-day cooldown check
      final int? lastDismissedMs = prefs.getInt(
        'notification_card_dismissed_time',
      );
      bool isCooldownActive = false;
      if (lastDismissedMs != null) {
        final lastDismissedDate = DateTime.fromMillisecondsSinceEpoch(
          lastDismissedMs,
        );
        final daysDifference = DateTime.now()
            .difference(lastDismissedDate)
            .inDays;
        isCooldownActive = daysDifference < 7;
      }

      // Hide card if granted, settings disabled, or cooldown active (< 7 days)
      if (isGranted || !appSettingsEnabled || isCooldownActive) {
        InlineNotificationCard.cachedShouldShow = false;
        if (_isVisible.value) {
          await _animationController.reverse();
          if (mounted) _isVisible.value = false;
        }
        return;
      }

      // Cooldown expired and permission not yet granted: display card
      InlineNotificationCard.cachedShouldShow = true;
      if (!_isVisible.value) {
        _isVisible.value = true;
        _animationController.forward();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InlineNotificationCard: permission check failed: $e');
      }
      if (mounted && InlineNotificationCard.cachedShouldShow != true) {
        _isVisible.value = false;
      }
    }
  }

  Future<void> _requestPermission() async {
    di.sl<HapticService>().selection();
    final currentStatus = await Permission.notification.status;
    if (!mounted) return;

    if (currentStatus.isPermanentlyDenied) {
      await openAppSettings();
      _dismissCard();
      return;
    }

    final bool isGranted;
    if (di.sl.isRegistered<NotificationService>()) {
      isGranted = await di.sl<NotificationService>().requestPermissions();
    } else {
      final status = await Permission.notification.request();
      isGranted = status.isGranted;
    }
    if (!mounted) return;

    if (isGranted) {
      di.sl<HapticService>().success();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', true);
        await prefs.setBool('notification_permission_granted', true);
        if (di.sl.isRegistered<NotificationService>()) {
          di.sl<NotificationService>().onNotificationPreferenceChanged(true);
        }
      } catch (_) {}
      InlineNotificationCard.cachedShouldShow = false;
      await _animationController.reverse();
      if (mounted) _isVisible.value = false;
    } else {
      _dismissCard();
    }
  }

  Future<void> _dismissCard() async {
    di.sl<HapticService>().light();
    InlineNotificationCard.cachedShouldShow = false;
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
    _isVisible.dispose();
    super.dispose();
  }

  String _getDynamicTitle() {
    final streak = widget.streak;

    if (streak >= 3) {
      return context.tr(
        'notification_card.streak_protect',
        args: [streak.toString()],
        fallback: "Save your {}-day streak!",
      );
    } else if (streak == 1 || streak == 2) {
      return context.tr(
        'notification_card.starter_momentum',
        fallback: "Keep your streak going!",
      );
    }

    // Streak is 0
    return context.tr(
      'notification_card.morning_quest',
      fallback: 'Start your streak today!',
    );
  }

  String _getDynamicSubtitle() {
    if (widget.streak >= 3) {
      return context.tr(
        'notification_card.subtitle_streak_short',
        fallback: "A quick alert before midnight so you never lose it",
      );
    } else if (widget.streak == 1 || widget.streak == 2) {
      return context.tr(
        'notification_card.subtitle_momentum',
        fallback: 'A quick daily reminder to help you hit a 7-day streak',
      );
    }

    return context.tr(
      'notification_card.subtitle_default_short',
      fallback: 'A quick 2-minute reminder so you never miss a day',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
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
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.25,
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.screen, 14.h, AppSpacing.screen, 0),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isMidnight
                        ? AppColors.midnightSurface
                        : (isDark
                            ? const Color(0xFF131A29)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isMidnight
                          ? Colors.white.withValues(alpha: 0.12)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate100),
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardCompact,
                      vertical: 10.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Leading Notification Icon — Vertically Centered Anchor
                        Container(
                          width: 36.r,
                          height: 36.r,
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
                              size: 18.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),

                        // Main Content (Title Row + Subtitle/CTA Row)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Row 1: Full-Width Title + Pinned Top-Right Close
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: AutoSizeText(
                                        title,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.slate900,
                                          height: 1.15,
                                        ),
                                        maxLines: 1,
                                        minFontSize: 11,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),

                                  // Pinned Close Button (✕) with generous hit box
                                  Semantics(
                                    button: true,
                                    label: context.tr(
                                      'common.close',
                                      fallback: 'Close',
                                    ),
                                    child: GestureDetector(
                                      onTap: _dismissCard,
                                      behavior: HitTestBehavior.opaque,
                                      child: SizedBox(
                                        width: 32.r,
                                        height: 32.r,
                                        child: Center(
                                          child: Container(
                                            width: 19.r,
                                            height: 19.r,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.05,
                                                    ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 11.5.r,
                                              color: isDark
                                                  ? Colors.white60
                                                  : AppColors.slate500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Tight, professional typography gap between title and subtitle
                              SizedBox(height: 3.h),

                              // Row 2: Subtitle on Left (2 lines) + Remind Me CTA on Bottom-Right
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.65,
                                              )
                                            : AppColors.slate600,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),

                                  // Remind Me Action Pill
                                  ScaleButton(
                                    onTap: _requestPermission,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 11.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: IllustrationColors.warmOrange,
                                        borderRadius:
                                            BorderRadius.circular(9.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: IllustrationColors.warmOrange
                                                .withValues(alpha: 0.35),
                                            blurRadius: 5,
                                            offset: const Offset(0, 1.5),
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
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                          height: 1.1,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
