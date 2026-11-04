import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Authoritative glassmorphic confirmation modal for exiting/forfeiting an active Arena duel.
class ArenaQuitMatchDialog extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onForfeit;

  const ArenaQuitMatchDialog({
    super.key,
    required this.onStay,
    required this.onForfeit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required VoidCallback onForfeit,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArenaQuitMatchDialog(
        onStay: () => Navigator.of(ctx).pop(false),
        onForfeit: () {
          Navigator.of(ctx).pop(true);
          onForfeit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;
    final borderColor = isDark ? AppColors.slate700 : AppColors.slate200;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: borderColor, width: 1.r),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(22.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: AppColors.rose500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.rose500.withValues(alpha: 0.25),
                    width: 2.r,
                  ),
                ),
                child: Icon(
                  LucideIcons.alertTriangle,
                  size: 28.sp,
                  color: AppColors.rose500,
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Forfeit 1v1 Arena Duel?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Leaving mid-match will immediately count as a forfeit defeat. Your 30-coin stake will be transferred to your opponent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 22.h),
            // Primary Action: Stay & Fight
            ElevatedButton(
              onPressed: onStay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.swords, size: 16.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'Stay & Fight',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            // Secondary Action: Forfeit
            OutlinedButton(
              onPressed: onForfeit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rose500,
                side: BorderSide(color: AppColors.rose500.withValues(alpha: 0.4)),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Forfeit Match (-30 🪙)',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.rose500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
