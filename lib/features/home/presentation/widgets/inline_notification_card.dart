import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class InlineNotificationCard extends StatefulWidget {
  final int streak;

  const InlineNotificationCard({super.key, required this.streak});

  @override
  State<InlineNotificationCard> createState() => _InlineNotificationCardState();
}

class _InlineNotificationCardState extends State<InlineNotificationCard>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
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
    final prefs = await SharedPreferences.getInstance();
    final bool isGranted = await Permission.notification.isGranted;
    final bool isDeniedForever =
        await Permission.notification.isPermanentlyDenied;

    // If user explicitly disabled notifications from Settings Screen, we respect that too.
    final bool appSettingsEnabled =
        prefs.getBool('notifications_enabled') ?? true;

    if (isGranted || isDeniedForever || !appSettingsEnabled) {
      if (mounted) setState(() => _isVisible = false);
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
        if (mounted) setState(() => _isVisible = false);
        return;
      }
    }

    if (mounted) {
      setState(() => _isVisible = true);
      _animationController.forward();
    }
  }

  Future<void> _requestPermission() async {
    di.sl<HapticService>().selection();
    final status = await Permission.notification.request();

    if (status.isGranted) {
      di.sl<HapticService>().success();
      if (mounted) {
        await _animationController.reverse();
        setState(() => _isVisible = false);
      }
    } else {
      _dismissCard();
    }
  }

  Future<void> _dismissCard() async {
    di.sl<HapticService>().light();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'notification_card_dismissed_time',
      DateTime.now().millisecondsSinceEpoch,
    );

    if (mounted) {
      await _animationController.reverse();
      setState(() => _isVisible = false);
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
        'Protect your $streak-Day Streak!',
        '$streak days strong! Keep it up.',
        'Unstoppable! Protect your streak.',
        "Don't lose your $streak-day progress!"
      ];
      return streakTitles[hour % streakTitles.length];
    } else if (streak == 1 || streak == 2) {
      final starterTitles = [
        'You are on a roll! 🚀',
        'Keep the momentum going!',
        'Your journey has just begun!',
      ];
      return starterTitles[hour % starterTitles.length];
    }

    // Streak is 0
    if (hour < 12) {
      return 'Morning Quest Ready! ☀️';
    } else if (hour < 17) {
      return 'Afternoon Practice? 🦉';
    } else if (hour < 21) {
      return 'Evening Knowledge Boost 🌙';
    } else {
      return 'Night Owl Training 🌌';
    }
  }

  String _getDynamicSubtitle() {
    if (widget.streak >= 3) {
      return 'Enable notifications so Owly can remind you to protect your streak.';
    }
    return 'Turn on notifications so Owly can remind you to practice daily.';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizeTransition(
      sizeFactor: _animationController,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.orange,
                              size: 24.r,
                            ),
                            Positioned(
                              top: 10.r,
                              right: 12.r,
                              child: Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 24.w),
                              child: Text(
                                _getDynamicTitle(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _getDynamicSubtitle(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40.h,
                                    child: ElevatedButton(
                                      onPressed: _requestPermission,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
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
                                        'Remind Me',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: SizedBox(
                                    height: 40.h,
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
                                        'Not Now',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
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
                Positioned(
                  top: 12.r,
                  right: 12.r,
                  child: GestureDetector(
                    onTap: _dismissCard,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
