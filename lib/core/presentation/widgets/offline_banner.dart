import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// A slim, non-blocking banner displayed at the top of the screen when
/// the device loses internet connectivity during gameplay.
///
/// Unlike the full-screen [NoInternetPage], this widget does NOT block
/// interaction — it informs the user that progress will sync later while
/// allowing uninterrupted gameplay (since quest data is loaded from local
/// assets and does not require an active internet connection).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.wifiOff,
                color: Colors.amber,
                size: 18.r,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  context.tr(
                    'connectivity.offline_banner',
                    fallback: 'You\'re offline. Progress will sync later.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -1, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}
