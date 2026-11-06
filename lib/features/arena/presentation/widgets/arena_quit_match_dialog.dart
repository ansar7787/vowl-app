import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Clean, human-centered confirmation modal for exiting/forfeiting an active Arena match
/// or leaving a private room lobby. Free of AI buzzwords, clutter, and redundant text.
class ArenaQuitMatchDialog extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onForfeit;
  final bool isWaitingLobby;

  const ArenaQuitMatchDialog({
    super.key,
    required this.onStay,
    required this.onForfeit,
    this.isWaitingLobby = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required VoidCallback onForfeit,
    bool isWaitingLobby = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArenaQuitMatchDialog(
        isWaitingLobby: isWaitingLobby,
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
    final borderColor = isDark
        ? AppColors.indigo500.withValues(alpha: 0.22)
        : AppColors.slate200;

    final accentColor = isWaitingLobby ? AppColors.indigo500 : AppColors.rose500;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onStay();
      },
      child: Dialog(
        backgroundColor: cardBg,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: borderColor, width: 1.2.r),
        ),
        elevation: 16,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Clean Alert Icon
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isWaitingLobby ? LucideIcons.doorOpen : LucideIcons.alertTriangle,
                    size: 24.r,
                    color: accentColor,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // 2. Direct, Natural Title
              Text(
                isWaitingLobby ? 'Leave Room?' : 'Forfeit Match?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 8.h),

              // 3. Clear, Single-Sentence Explanation
              Text(
                isWaitingLobby
                    ? 'No opponent has joined yet. Leaving will close this room and return your 30 coins.'
                    : 'If you leave now, you forfeit this match and lose your 30 coins.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 22.h),

              // 4. Primary Action: Safe & Encouraging
              ScaleButton(
                onTap: onStay,
                child: Container(
                  height: 46.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.indigo500,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    isWaitingLobby ? 'Keep Waiting' : 'Keep Playing',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // 5. Destructive Action: Transparent & Uncluttered
              ScaleButton(
                onTap: onForfeit,
                child: Container(
                  height: 38.h,
                  alignment: Alignment.center,
                  child: Text(
                    isWaitingLobby ? 'Leave Room' : 'Forfeit (-30🪙)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isWaitingLobby ? textSecondary : AppColors.rose500,
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
