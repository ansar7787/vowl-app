import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class InlineNotificationCard extends StatefulWidget {
  final int streak;

  const InlineNotificationCard({super.key, required this.streak});

  @override
  State<InlineNotificationCard> createState() => _InlineNotificationCardState();
}

class _InlineNotificationCardState extends State<InlineNotificationCard> with SingleTickerProviderStateMixin {
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
    final bool isDeniedForever = await Permission.notification.isPermanentlyDenied;
    
    // If user explicitly disabled notifications from Settings Screen, we respect that too.
    final bool appSettingsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (isGranted || isDeniedForever || !appSettingsEnabled) {
      if (mounted) setState(() => _isVisible = false);
      return;
    }

    // Cooldown logic: don't show every single time if they dismissed it.
    final int? lastDismissedMs = prefs.getInt('notification_card_dismissed_time');
    if (lastDismissedMs != null) {
      final lastDismissedDate = DateTime.fromMillisecondsSinceEpoch(lastDismissedMs);
      final daysDifference = DateTime.now().difference(lastDismissedDate).inDays;
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
    await prefs.setInt('notification_card_dismissed_time', DateTime.now().millisecondsSinceEpoch);
    
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GlassTile(
                padding: EdgeInsets.all(20.r),
                borderRadius: BorderRadius.circular(24.r),
                child: Row(
                  children: [
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
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
                          Text(
                            widget.streak >= 3 ? 'Protect your ${widget.streak}-Day Streak!' : 'Never miss a quest!',
                            style: TextStyle(fontFamily: 'Outfit', 
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Enable notifications so Owly can remind you to practice.',
                            style: TextStyle(fontFamily: 'Outfit', 
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _requestPermission,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Remind Me',
                                    style: TextStyle(fontFamily: 'Outfit', 
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _dismissCard,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                                    side: BorderSide(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Not Now',
                                    style: TextStyle(fontFamily: 'Outfit', 
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
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
              // Close button
              Positioned(
                top: -8.r,
                right: -8.r,
                child: GestureDetector(
                  onTap: _dismissCard,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
    );
  }
}
