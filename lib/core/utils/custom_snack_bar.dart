import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
enum CustomSnackBarType { success, error, info, warning }

/// Centered premium UI snackbar controller mapped to modern curated color scales,
/// ensuring safe rendering and prevent crashes on unmounted view scopes.
class CustomSnackBar {
  /// Displays a customized, floating floating alert box.
  static void show({
    required BuildContext context,
    required String message,
    required CustomSnackBarType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Defensive check preventing runtime exceptions on unmounted build elements
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Curated Premium Theme Colors matching our 10/10 design system
    Color baseBgColor;
    Color accentColor;
    IconData icon;
    String title;

    switch (type) {
      case CustomSnackBarType.success:
        baseBgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        accentColor = const Color(0xFF10B981); // Emerald
        icon = Icons.check_circle_rounded;
        title = 'Success';
        break;
      case CustomSnackBarType.error:
        baseBgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
        accentColor = const Color(0xFFEF4444); // Red/Rose
        icon = Icons.error_rounded;
        title = 'Oops!';
        break;
      case CustomSnackBarType.warning:
        baseBgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
        accentColor = const Color(0xFFF59E0B); // Amber
        icon = Icons.warning_rounded;
        title = 'Notice';
        break;
      case CustomSnackBarType.info:
        baseBgColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
        accentColor = const Color(0xFF3B82F6); // Blue
        icon = Icons.info_rounded;
        title = 'Tip';
        break;
    }

    final cardBgColor = isDark 
        ? baseBgColor.withValues(alpha: 0.85) 
        : baseBgColor.withValues(alpha: 0.95);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B);

    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Elegant accent colored side indicator
              Container(
                width: 6.w,
                color: accentColor,
              ),
              // 2. Main content area
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Icon
                      Icon(
                        icon,
                        color: accentColor,
                        size: 22.r,
                      ),
                      SizedBox(width: 12.w),
                      // Text Hierarchies
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(fontFamily: 'Outfit', 
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: 0.3,
                                ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              message,
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: subtextColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 3. Dismiss button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Safe guard check on context execution limits
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Icon(
                      Icons.close_rounded,
                      color: subtextColor,
                      size: 18.r,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
